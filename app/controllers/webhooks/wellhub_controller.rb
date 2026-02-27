module Webhooks
  class WellhubController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    rescue_from ActionDispatch::Http::Parameters::ParseError do
      head :bad_request
    end

    before_action :verify_signature

    def create
      event = params[:event] || params[:type]
      payload = JSON.parse(@raw_body)

      Rails.logger.info "Wellhub webhook received: #{event}"

      case event
      when "checkin"
        WellhubCheckinService.process(payload)
      when "booking-requested"
        WellhubBookingService.booking_requested(payload)
      when "booking-cancelled"
        WellhubBookingService.booking_cancelled(payload)
      when "booking-checked-in"
        WellhubBookingService.booking_checked_in(payload)
      when "system-integration-requested"
        WellhubSetupService.integration_requested(payload)
      else
        Rails.logger.info "Unhandled Wellhub event: #{event}"
      end

      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def verify_signature
      @raw_body = request.body.read
      request.body.rewind

      signature = request.headers["X-Gympass-Signature"]

      if signature.blank?
        head :unauthorized and return
      end

      expected = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha1"),
        webhook_secret,
        @raw_body
      )

      unless ActiveSupport::SecurityUtils.secure_compare(expected.downcase, signature.downcase)
        head :unauthorized and return
      end
    end

    def webhook_secret
      ENV.fetch("WELLHUB_WEBHOOK_SECRET")
    end
  end
end
