class PackageExpirationWarningJob < ApplicationJob
  queue_as :mailers

  def perform
    warning_date = 3.days.from_now.to_date

    expiring_packages = UserPackage.where(status: "active")
      .where(expires_at: warning_date.beginning_of_day..warning_date.end_of_day)
      .where("credits_remaining > 0")
      .includes(:user, :package)

    expiring_packages.find_each do |user_package|
      PackageMailer.expiring_soon(user_package).deliver_later
    end
  end
end
