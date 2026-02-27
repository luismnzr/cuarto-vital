class PackageMailer < ApplicationMailer
  def purchased(user_package)
    @user_package = user_package
    @user = user_package.user
    @package = user_package.package

    mail(to: @user.email, subject: "Package Purchased — #{@package.name}")
  end

  def expiring_soon(user_package)
    @user_package = user_package
    @user = user_package.user
    @package = user_package.package

    mail(to: @user.email, subject: "Your Package Expires Soon")
  end

  def expired(user_package)
    @user_package = user_package
    @user = user_package.user
    @package = user_package.package

    mail(to: @user.email, subject: "Your Package Has Expired")
  end
end
