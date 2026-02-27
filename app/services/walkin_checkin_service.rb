class WalkinCheckinService
  Result = Struct.new(:success?, :reservation, :error, keyword_init: true)

  # Check in a user who already has credits or a subscription
  def self.checkin(user:, studio_class:)
    return Result.new(success?: false, error: "This class is full") if studio_class.full?

    existing = user.reservations.where(studio_class: studio_class).where.not(status: "cancelled").first
    if existing
      return Result.new(success?: false, error: "#{user.full_name} is already on the roster for this class")
    end

    unless user.can_reserve?
      return Result.new(success?: false, error: "#{user.full_name} has no active package or subscription")
    end

    ActiveRecord::Base.transaction do
      credit = nil

      if user.has_active_subscription?
        # Subscription users don't use credits
      elsif user.has_available_credits?
        deduction = CreditDeductionService.deduct(user)
        unless deduction.success?
          return Result.new(success?: false, error: deduction.error)
        end
        credit = deduction.credit
      end

      reservation = user.reservations.create!(
        studio_class: studio_class,
        status: "confirmed",
        class_credit: credit
      )

      studio_class.decrement!(:spots_remaining)

      return Result.new(success?: true, reservation: reservation)
    end
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success?: false, error: e.message)
  end

  # Walk-in purchase: sell a package in-person, then check in
  def self.walkin_purchase_and_checkin(user:, studio_class:, package:, payment_method:)
    return Result.new(success?: false, error: "This class is full") if studio_class.full?

    existing = user.reservations.where(studio_class: studio_class).where.not(status: "cancelled").first
    if existing
      return Result.new(success?: false, error: "#{user.full_name} is already on the roster for this class")
    end

    ActiveRecord::Base.transaction do
      currency = StudioSetting.get("currency") || "mxn"

      # Create the package for the user
      user_package = UserPackage.create!(
        user: user,
        package: package,
        credits_remaining: package.credit_count,
        status: "active",
        purchased_at: Time.current,
        expires_at: Time.current + package.expiration_days.days
      )

      # Record the payment
      Payment.create!(
        user: user,
        amount: package.price,
        currency: currency,
        status: "succeeded",
        payment_method: payment_method,
        description: "#{package.name} — in-person purchase",
        payable: user_package
      )

      # Deduct a credit and create reservation
      credit = user_package.use_credit!

      reservation = user.reservations.create!(
        studio_class: studio_class,
        status: "confirmed",
        class_credit: credit
      )

      studio_class.decrement!(:spots_remaining)

      Result.new(success?: true, reservation: reservation)
    end
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success?: false, error: e.message)
  end
end
