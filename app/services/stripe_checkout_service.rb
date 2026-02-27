class StripeCheckoutService
  class << self
    def create_package_session(user:, package:, success_url:, cancel_url:)
      customer_id = StripeCustomerService.find_or_create(user)
      currency = StudioSetting.get("currency") || "mxn"

      Stripe::Checkout::Session.create(
        customer: customer_id,
        mode: "payment",
        line_items: [{
          price_data: {
            currency: currency,
            unit_amount: (package.price * 100).to_i,
            product_data: {
              name: package.name,
              description: "#{package.credit_count} classes — valid for #{package.expiration_days} days"
            }
          },
          quantity: 1
        }],
        metadata: {
          type: "package",
          package_id: package.id,
          user_id: user.id
        },
        success_url: success_url,
        cancel_url: cancel_url
      )
    end

    def create_subscription_session(user:, plan:, success_url:, cancel_url:)
      customer_id = StripeCustomerService.find_or_create(user)
      ensure_stripe_price(plan) if plan.stripe_price_id.blank?

      Stripe::Checkout::Session.create(
        customer: customer_id,
        mode: "subscription",
        line_items: [{
          price: plan.stripe_price_id,
          quantity: 1
        }],
        metadata: {
          type: "subscription",
          subscription_plan_id: plan.id,
          user_id: user.id
        },
        success_url: success_url,
        cancel_url: cancel_url
      )
    end

    private

    def ensure_stripe_price(plan)
      currency = StudioSetting.get("currency") || "mxn"

      product = Stripe::Product.create(
        name: plan.name,
        description: plan.description.presence || "Unlimited classes"
      )

      price = Stripe::Price.create(
        product: product.id,
        unit_amount: (plan.price * 100).to_i,
        currency: currency,
        recurring: { interval: plan.interval == "annual" ? "year" : "month" }
      )

      plan.update!(stripe_price_id: price.id)
    end

    def create_portal_session(user:, return_url:)
      raise "User has no Stripe customer ID" if user.stripe_customer_id.blank?

      Stripe::BillingPortal::Session.create(
        customer: user.stripe_customer_id,
        return_url: return_url
      )
    end
  end
end
