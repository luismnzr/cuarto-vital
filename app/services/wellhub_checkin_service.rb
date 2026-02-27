class WellhubCheckinService
  class << self
    def process(payload)
      gympass_id = payload.dig("user", "unique_token") || payload["gympass_id"]
      gym_id = payload["gym_id"] || StudioSetting.wellhub_gym_id

      unless gympass_id
        Rails.logger.warn "Wellhub checkin webhook missing user identifier"
        return
      end

      # Validate the check-in with Wellhub (triggers payment)
      begin
        WellhubClient.validate_checkin(gym_id: gym_id, gympass_id: gympass_id)
      rescue WellhubClient::Error => e
        Rails.logger.error "Wellhub checkin validation failed: #{e.message} (status: #{e.status})"
        return
      end

      # Find the class — prefer the user's booking, fall back to time-based match
      studio_class = find_class_for_user(gympass_id)
      return unless studio_class

      ExternalCheckin.find_or_create_by!(
        user_identifier: gympass_id,
        platform: "wellhub",
        studio_class: studio_class
      ) do |checkin|
        checkin.checked_in_at = Time.current
        checkin.validated = true
        checkin.external_reference_id = payload["checkin_id"]
      end

      # Mark the booking as checked in if one exists
      booking = WellhubBooking.accepted.find_by(
        studio_class: studio_class,
        gympass_id: gympass_id
      )
      booking&.check_in!
    end

    private

    def find_class_for_user(gympass_id)
      # First: check if this user has an accepted booking for a class today
      booking = WellhubBooking.accepted
                              .where(gympass_id: gympass_id)
                              .joins(:studio_class)
                              .where(studio_classes: { date: Date.current, status: "scheduled" })
                              .order("studio_classes.start_time ASC")
                              .first

      return booking.studio_class if booking

      # Fallback: find the class happening right now or next upcoming today
      StudioClass.scheduled
                 .where(date: Date.current)
                 .where("start_time <= ? AND end_time >= ?", Time.current.strftime("%H:%M:%S"), Time.current.strftime("%H:%M:%S"))
                 .order(:start_time)
                 .first ||
      StudioClass.scheduled
                 .where(date: Date.current)
                 .where("start_time >= ?", Time.current.strftime("%H:%M:%S"))
                 .order(:start_time)
                 .first
    end
  end
end
