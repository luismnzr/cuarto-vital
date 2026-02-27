class StripeWebhookService
  class << self
    def process(event)
      # Idempotency: skip if this event was already processed
      if StripeWebhookEvent.processed?(event.id)
        Rails.logger.info "Skipping already-processed Stripe event: #{event.id} (#{event.type})"
        return
      end

      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "invoice.paid"
        handle_invoice_paid(event.data.object)
      when "invoice.payment_failed"
        handle_invoice_payment_failed(event.data.object)
      when "customer.subscription.updated"
        handle_subscription_updated(event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event.data.object)
      else
        Rails.logger.info "Unhandled Stripe event: #{event.type}"
        return
      end

      StripeWebhookEvent.record!(event.id, event.type)
    rescue ActiveRecord::RecordNotUnique
      # Another thread/process already recorded this event — safe to ignore
      Rails.logger.info "Stripe event #{event.id} was processed concurrently, skipping"
    end

    private

    def handle_checkout_completed(session)
      metadata = session.metadata

      case metadata["type"]
      when "package"
        fulfill_package(session, metadata)
      when "subscription"
        fulfill_subscription(session, metadata)
      end
    end

    def fulfill_package(session, metadata)
      user = User.find(metadata["user_id"])
      package = Package.find(metadata["package_id"])

      user_package = nil
      ActiveRecord::Base.transaction do
        user_package = user.user_packages.create!(
          package: package,
          purchased_at: Time.current,
          expires_at: Time.current + package.expiration_days.days,
          credits_remaining: package.credit_count,
          status: "active",
          stripe_payment_intent_id: session.payment_intent
        )

        user.payments.create!(
          stripe_checkout_session_id: session.id,
          stripe_payment_intent_id: session.payment_intent,
          amount: package.price,
          currency: session.currency || "mxn",
          status: "succeeded",
          description: "Package: #{package.name}",
          payable: user_package
        )
      end

      PackageMailer.purchased(user_package).deliver_later
    end

    def fulfill_subscription(session, metadata)
      user = User.find(metadata["user_id"])
      plan = SubscriptionPlan.find(metadata["subscription_plan_id"])

      stripe_subscription = Stripe::Subscription.retrieve(session.subscription)

      currency = session.currency.presence || StudioSetting.get("currency").presence || "mxn"

      user_sub = nil
      ActiveRecord::Base.transaction do
        user_sub = user.user_subscription || user.build_user_subscription
        user_sub.update!(
          subscription_plan: plan,
          stripe_subscription_id: stripe_subscription.id,
          stripe_customer_id: session.customer,
          status: "active",
          current_period_start: Time.at(sub_period(stripe_subscription).current_period_start),
          current_period_end: Time.at(sub_period(stripe_subscription).current_period_end)
        )

        # stripe_checkout_session_id is the unique identifier for this payment;
        # stripe_payment_intent_id is left nil because Stripe API 2025-03-31
        # removed invoice.payment_intent in favour of invoice.payments list.
        user.payments.create!(
          stripe_checkout_session_id: session.id,
          amount: plan.price,
          currency: currency,
          status: "succeeded",
          payment_method: "stripe",
          description: "Subscription: #{plan.name}",
          payable: user_sub
        )
      end

      SubscriptionMailer.confirmed(user_sub).deliver_later
    end

    def handle_invoice_paid(invoice)
      return if invoice.billing_reason == "subscription_create" # Already handled by checkout

      subscription_id = invoice.subscription
      return unless subscription_id

      user_sub = UserSubscription.find_by(stripe_subscription_id: subscription_id)
      return unless user_sub

      # Use invoice.period_start/end directly — avoids an extra API call and
      # works with Stripe API 2025-03-31 which removed current_period_* from Subscription.
      user_sub.update!(
        status: "active",
        current_period_start: Time.at(invoice.period_start),
        current_period_end: Time.at(invoice.period_end)
      )

      # Stripe API 2025-03-31 removed invoice.payment_intent; use payments list instead
      payment_intent_id = invoice.payments&.data&.first&.payment&.payment_intent

      user_sub.user.payments.create!(
        stripe_payment_intent_id: payment_intent_id,
        amount: invoice.amount_paid / 100.0,
        currency: invoice.currency,
        status: "succeeded",
        payment_method: "stripe",
        description: "Subscription renewal: #{user_sub.subscription_plan.name}",
        payable: user_sub
      )
    end

    def handle_invoice_payment_failed(invoice)
      subscription_id = invoice.subscription
      return unless subscription_id

      user_sub = UserSubscription.find_by(stripe_subscription_id: subscription_id)
      return unless user_sub

      user_sub.update!(status: "past_due")

      SubscriptionMailer.renewal_failed(user_sub).deliver_later
    end

    def handle_subscription_updated(subscription)
      user_sub = UserSubscription.find_by(stripe_subscription_id: subscription.id)
      return unless user_sub

      status = case subscription.status
               when "active" then "active"
               when "past_due" then "past_due"
               when "canceled", "unpaid" then "cancelled"
               else "inactive"
               end

      user_sub.update!(
        status: status,
        current_period_start: Time.at(sub_period(subscription).current_period_start),
        current_period_end: Time.at(sub_period(subscription).current_period_end)
      )
    end

    def handle_subscription_deleted(subscription)
      user_sub = UserSubscription.find_by(stripe_subscription_id: subscription.id)
      return unless user_sub

      user_sub.update!(status: "cancelled")
    end

    # Stripe API 2025-03-31 removed current_period_start/end from the Subscription
    # object; they now live on each SubscriptionItem.
    def sub_period(subscription)
      subscription.items.data.first
    end
  end
end
