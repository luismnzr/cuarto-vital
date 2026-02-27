class WellhubSetupService
  class << self
    # Called when a studio selects Cuarto Vital as their CMS in the Wellhub portal.
    # Stores the gym_id and registers webhooks, but does NOT auto-enable —
    # the admin must enable Wellhub from the settings page.
    def integration_requested(payload)
      gym_id = payload["gym_id"]

      Rails.logger.info "Wellhub integration requested for gym #{gym_id}"

      # Store the gym_id if not already set, but don't overwrite an existing one
      current_gym_id = StudioSetting.get("wellhub_gym_id")
      if current_gym_id.blank?
        StudioSetting.set("wellhub_gym_id", gym_id)
      elsif current_gym_id != gym_id
        Rails.logger.warn "Wellhub integration requested with different gym_id: #{gym_id} (current: #{current_gym_id})"
        return
      end

      # Register our webhook URLs for this gym
      base_url = resolve_base_url
      webhook_url = "#{base_url}/webhooks/wellhub"

      WellhubClient.register_webhooks(
        gym_id: gym_id,
        webhooks: [
          { event: "checkin", url: webhook_url },
          { event: "booking-requested", url: webhook_url },
          { event: "booking-cancelled", url: webhook_url },
          { event: "booking-checked-in", url: webhook_url }
        ]
      )

      Rails.logger.info "Registered Wellhub webhooks for gym #{gym_id}. Admin must enable integration from Settings."
    rescue WellhubClient::Error => e
      Rails.logger.error "Failed to register Wellhub webhooks for gym #{gym_id}: #{e.message}"
    end

    private

    def resolve_base_url
      host = ENV["APP_HOST"]
      if host.present?
        host.start_with?("http") ? host : "https://#{host}"
      elsif ENV["HEROKU_APP_NAME"].present?
        "https://#{ENV['HEROKU_APP_NAME']}.herokuapp.com"
      else
        raise "APP_HOST must be set to register Wellhub webhooks"
      end
    end
  end
end
