class CheckoutsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def create_package
    package = Package.active.find(params[:package_id])

    session = StripeCheckoutService.create_package_session(
      user: current_user,
      package: package,
      success_url: checkout_success_url(type: "package"),
      cancel_url: packages_url
    )

    redirect_to session.url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => e
    flash[:alert] = "Payment error: #{e.message}"
    redirect_to packages_path
  end

  def create_subscription
    plan = SubscriptionPlan.active.find(params[:plan_id])

    if current_user.has_active_subscription?
      flash[:alert] = "You already have an active subscription. Manage it from your profile."
      redirect_to profile_subscription_path and return
    end

    session = StripeCheckoutService.create_subscription_session(
      user: current_user,
      plan: plan,
      success_url: checkout_success_url(type: "subscription"),
      cancel_url: packages_url
    )

    redirect_to session.url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => e
    flash[:alert] = "Payment error: #{e.message}"
    redirect_to packages_path
  end

  def success
    flash[:notice] = case params[:type]
                     when "package"
                       "Package purchased successfully! Your credits are now available."
                     when "subscription"
                       "Subscription activated! You now have unlimited access."
                     else
                       "Payment completed successfully!"
                     end
    redirect_to profile_path
  end

  def customer_portal
    session = StripeCheckoutService.create_portal_session(
      user: current_user,
      return_url: profile_subscription_url
    )

    redirect_to session.url, allow_other_host: true, status: :see_other
  rescue => e
    flash[:alert] = "Unable to open billing portal: #{e.message}"
    redirect_to profile_subscription_path
  end
end
