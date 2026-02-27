class PackageExpirationJob < ApplicationJob
  queue_as :default

  def perform
    expired_packages = UserPackage.where(status: "active")
      .where("expires_at <= ?", Time.current)
      .includes(:user, :package)

    expired_packages.find_each do |user_package|
      user_package.update!(status: "expired")
      PackageMailer.expired(user_package).deliver_later
    end
  end
end
