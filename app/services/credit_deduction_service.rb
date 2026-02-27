class CreditDeductionService
  Result = Struct.new(:success?, :credit, :error, keyword_init: true)

  def self.deduct(user)
    package = user.active_package
    return Result.new(success?: false, error: "No active package with available credits") unless package

    credit = package.use_credit!
    Result.new(success?: true, credit: credit)
  rescue => e
    Result.new(success?: false, error: e.message)
  end

  def self.restore(reservation)
    return unless reservation.class_credit

    package = reservation.class_credit.user_package
    package.restore_credit!(reservation.class_credit)
  end
end
