class ReservationService
  Result = Struct.new(:success?, :reservation, :error, keyword_init: true)

  def self.reserve(user:, studio_class:)
    return Result.new(success?: false, error: "This class is no longer available") unless studio_class.status == "scheduled"
    return Result.new(success?: false, error: "This class has already started") if studio_class.starts_at && studio_class.starts_at <= Time.current
    return Result.new(success?: false, error: "This class is full") if studio_class.full?
    return Result.new(success?: false, error: "You already have a reservation for this class") if user.reservations.confirmed.where(studio_class: studio_class).exists?

    unless user.can_reserve?
      return Result.new(success?: false, error: "You need an active package or subscription to reserve a class")
    end

    error = nil

    ActiveRecord::Base.transaction do
      credit = nil

      if user.has_active_subscription?
        # Subscription users don't use credits
      elsif user.has_available_credits?
        deduction = CreditDeductionService.deduct(user)
        unless deduction.success?
          error = deduction.error
          raise ActiveRecord::Rollback
        end
        credit = deduction.credit
      end

      reservation = user.reservations.create!(
        studio_class: studio_class,
        status: "confirmed",
        class_credit: credit
      )

      studio_class.decrement!(:spots_remaining)

      ReservationMailer.confirmed(reservation).deliver_later

      return Result.new(success?: true, reservation: reservation)
    end

    Result.new(success?: false, error: error || "Unable to complete reservation")
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success?: false, error: e.message)
  end

  def self.cancel(reservation:)
    studio_class = reservation.studio_class
    cancellation_window = StudioSetting.cancellation_window_hours
    late = studio_class.starts_at && studio_class.starts_at - Time.current < cancellation_window.hours

    ActiveRecord::Base.transaction do
      reservation.cancel!(late: late)

      # Restore credit if not a late cancel (or if late cancel doesn't forfeit)
      if reservation.class_credit.present?
        if !late || !StudioSetting.late_cancel_forfeit_credit?
          CreditDeductionService.restore(reservation)
        end
      end

      studio_class.increment!(:spots_remaining)

      # Promote next waitlist entry synchronously so the spot is never publicly open
      if studio_class.waitlist_count > 0
        WaitlistService.promote_next(studio_class: studio_class)
      end
    end

    ReservationMailer.cancelled(reservation).deliver_later

    Result.new(success?: true, reservation: reservation)
  rescue => e
    Result.new(success?: false, error: e.message)
  end
end
