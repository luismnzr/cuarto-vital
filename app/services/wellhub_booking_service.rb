class WellhubBookingService
  class << self
    # Wellhub user booked a class — accept or reject within 15 minutes
    def booking_requested(payload)
      booking_number = payload["booking_number"]
      gympass_id = payload.dig("user", "unique_token") || payload["gympass_id"]
      slot_id = payload["slot_id"]
      gym_id = payload["gym_id"] || StudioSetting.wellhub_gym_id

      # Idempotency: skip if already processed
      existing = WellhubBooking.find_by(booking_number: booking_number)
      if existing
        Rails.logger.info "Wellhub booking #{booking_number} already exists (status: #{existing.status})"
        return
      end

      studio_class = StudioClass.find_by(wellhub_slot_id: slot_id)

      unless studio_class
        Rails.logger.warn "Wellhub booking-requested for unknown slot: #{slot_id}"
        reject_booking(gym_id, booking_number)
        return
      end

      # Lock the row to prevent race conditions on spots_remaining
      accepted = false
      ActiveRecord::Base.transaction do
        studio_class.lock!

        if studio_class.full? || studio_class.status != "scheduled"
          reject_booking(gym_id, booking_number)
          WellhubBooking.create!(
            studio_class: studio_class,
            booking_number: booking_number,
            gympass_id: gympass_id,
            status: "rejected",
            booked_at: Time.current,
            responded_at: Time.current
          )
          next
        end

        WellhubBooking.create!(
          studio_class: studio_class,
          booking_number: booking_number,
          gympass_id: gympass_id,
          status: "accepted",
          booked_at: Time.current,
          responded_at: Time.current
        )

        studio_class.decrement!(:spots_remaining)
        accepted = true
      end

      if accepted
        accept_booking(gym_id, booking_number)
        sync_slot_capacity(studio_class.reload)
        notify_admin(booking_number)
      end
    end

    # Wellhub user cancelled their booking
    def booking_cancelled(payload)
      booking_number = payload["booking_number"]

      booking = WellhubBooking.find_by(booking_number: booking_number)
      unless booking
        Rails.logger.warn "Wellhub booking-cancelled for unknown booking: #{booking_number}"
        return
      end

      # Guard: only cancel bookings that are still active
      unless booking.status.in?(%w[pending accepted])
        Rails.logger.info "Wellhub booking #{booking_number} already #{booking.status}, skipping cancel"
        return
      end

      ActiveRecord::Base.transaction do
        studio_class = booking.studio_class
        studio_class.lock!

        booking.cancel!

        # Free up the spot, but don't exceed capacity
        if studio_class.spots_remaining < studio_class.capacity
          studio_class.increment!(:spots_remaining)
        end
      end

      sync_slot_capacity(booking.studio_class.reload)
    end

    # Wellhub user checked in at the gym with a pending booking
    def booking_checked_in(payload)
      booking_number = payload["booking_number"]

      booking = WellhubBooking.find_by(booking_number: booking_number)
      unless booking
        Rails.logger.warn "Wellhub booking-checked-in for unknown booking: #{booking_number}"
        return
      end

      return if booking.status == "checked_in"

      booking.check_in!

      # Record external check-in
      ExternalCheckin.find_or_create_by!(
        user_identifier: booking.gympass_id,
        platform: "wellhub",
        studio_class: booking.studio_class
      ) do |checkin|
        checkin.checked_in_at = Time.current
        checkin.validated = true
        checkin.external_reference_id = booking_number
      end
    end

    private

    def accept_booking(gym_id, booking_number)
      WellhubClient.update_booking(
        gym_id: gym_id,
        booking_number: booking_number,
        status: WellhubBooking::WELLHUB_STATUS_ACCEPTED
      )
    rescue WellhubClient::Error => e
      Rails.logger.error "Failed to accept Wellhub booking #{booking_number}: #{e.message}"
    end

    def reject_booking(gym_id, booking_number)
      WellhubClient.update_booking(
        gym_id: gym_id,
        booking_number: booking_number,
        status: WellhubBooking::WELLHUB_STATUS_REJECTED
      )
    rescue WellhubClient::Error => e
      Rails.logger.error "Failed to reject Wellhub booking #{booking_number}: #{e.message}"
    end

    def notify_admin(booking_number)
      booking = WellhubBooking.find_by(booking_number: booking_number)
      return unless booking

      WellhubBookingMailer.new_booking(booking).deliver_later
    rescue => e
      Rails.logger.error "Failed to send Wellhub booking notification: #{e.message}"
    end

    def sync_slot_capacity(studio_class)
      return unless studio_class.wellhub_slot_id

      template = studio_class.class_template
      return unless template.wellhub_class_id

      WellhubClient.update_slot(
        gym_id: StudioSetting.wellhub_gym_id,
        class_id: template.wellhub_class_id,
        slot_id: studio_class.wellhub_slot_id,
        attributes: {
          total_booked: studio_class.capacity - studio_class.spots_remaining,
          total_capacity: studio_class.capacity
        }
      )
    rescue WellhubClient::Error => e
      Rails.logger.error "Failed to sync slot capacity for class #{studio_class.id}: #{e.message}"
    end
  end
end
