require "test_helper"
require "ostruct"
require "minitest/mock"

class StripeWebhookServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, stripe_customer_id: "cus_test123")
    @package = create(:package, name: "10 Class Pack", price: 1000, credit_count: 10, expiration_days: 30)
    @plan = create(:subscription_plan, name: "Monthly", price: 1800, stripe_price_id: "price_test123")
  end

  test "fulfill_package creates user_package and payment" do
    session = OpenStruct.new(
      id: "cs_test_session_pkg",
      payment_intent: "pi_test_pkg",
      currency: "mxn",
      metadata: {
        "type" => "package",
        "package_id" => @package.id.to_s,
        "user_id" => @user.id.to_s
      }
    )

    event = OpenStruct.new(
      type: "checkout.session.completed",
      data: OpenStruct.new(object: session)
    )

    assert_difference -> { UserPackage.count } => 1, -> { Payment.count } => 1 do
      StripeWebhookService.process(event)
    end

    user_package = @user.user_packages.last
    assert_equal @package, user_package.package
    assert_equal 10, user_package.credits_remaining
    assert_equal "active", user_package.status
    assert_equal "pi_test_pkg", user_package.stripe_payment_intent_id

    payment = @user.payments.last
    assert_equal 1000, payment.amount
    assert_equal "succeeded", payment.status
    assert_equal "cs_test_session_pkg", payment.stripe_checkout_session_id
  end

  test "fulfill_subscription creates user_subscription and payment" do
    stripe_sub = OpenStruct.new(
      id: "sub_test123",
      latest_invoice: "in_test123",
      current_period: OpenStruct.new(start: 1.day.ago.to_i, end: 30.days.from_now.to_i)
    )

    session = OpenStruct.new(
      id: "cs_test_session_sub",
      payment_intent: nil,
      subscription: "sub_test123",
      customer: "cus_test123",
      currency: "mxn",
      metadata: {
        "type" => "subscription",
        "subscription_plan_id" => @plan.id.to_s,
        "user_id" => @user.id.to_s
      }
    )

    event = OpenStruct.new(
      type: "checkout.session.completed",
      data: OpenStruct.new(object: session)
    )

    mock = Minitest::Mock.new
    mock.expect :call, stripe_sub, ["sub_test123"]

    Stripe::Subscription.stub(:retrieve, mock) do
      assert_difference -> { UserSubscription.count } => 1, -> { Payment.count } => 1 do
        StripeWebhookService.process(event)
      end

      user_sub = @user.reload.user_subscription
      assert_equal "active", user_sub.status
      assert_equal "sub_test123", user_sub.stripe_subscription_id
      assert_equal @plan, user_sub.subscription_plan
    end
  end

  test "handle_subscription_deleted cancels subscription" do
    user_sub = create(:user_subscription, user: @user, subscription_plan: @plan,
                      stripe_subscription_id: "sub_to_cancel", status: "active")

    subscription_obj = OpenStruct.new(
      id: "sub_to_cancel",
      status: "canceled"
    )

    event = OpenStruct.new(
      type: "customer.subscription.deleted",
      data: OpenStruct.new(object: subscription_obj)
    )

    StripeWebhookService.process(event)

    assert_equal "cancelled", user_sub.reload.status
  end

  test "handle_invoice_payment_failed marks subscription as past_due" do
    user_sub = create(:user_subscription, user: @user, subscription_plan: @plan,
                      stripe_subscription_id: "sub_pastdue", status: "active")

    invoice = OpenStruct.new(
      subscription: "sub_pastdue",
      payment_intent: "pi_failed"
    )

    event = OpenStruct.new(
      type: "invoice.payment_failed",
      data: OpenStruct.new(object: invoice)
    )

    StripeWebhookService.process(event)

    assert_equal "past_due", user_sub.reload.status
  end
end
