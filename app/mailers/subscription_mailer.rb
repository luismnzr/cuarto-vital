class SubscriptionMailer < ApplicationMailer
  def confirmed(user_subscription)
    @subscription = user_subscription
    @user = user_subscription.user
    @plan = user_subscription.subscription_plan

    mail(to: @user.email, subject: "Subscription Confirmed — #{@plan.name}")
  end

  def renewal_failed(user_subscription)
    @subscription = user_subscription
    @user = user_subscription.user
    @plan = user_subscription.subscription_plan

    mail(to: @user.email, subject: "Payment Failed — Action Required")
  end
end
