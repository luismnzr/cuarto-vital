module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def create
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      begin
        event = Stripe::Webhook.construct_event(
          payload, sig_header, webhook_secret
        )
      rescue JSON::ParserError
        head :bad_request and return
      rescue Stripe::SignatureVerificationError
        head :bad_request and return
      end

      # Idempotency: skip if we've already processed this event
      if Payment.exists?(stripe_checkout_session_id: event.data.object.try(:id))
        head :ok and return if event.type == "checkout.session.completed"
      end

      begin
        StripeWebhookService.process(event)
      rescue => e
        Rails.logger.error "[StripeWebhook] #{e.class}: #{e.message}\n#{e.backtrace.first(10).join("\n")}"
        raise
      end

      head :ok
    end

    private

    def webhook_secret
      ENV.fetch("STRIPE_WEBHOOK_SECRET")
    end
  end
end
