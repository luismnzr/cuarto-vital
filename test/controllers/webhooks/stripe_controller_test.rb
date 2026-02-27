require "test_helper"

class Webhooks::StripeControllerTest < ActionDispatch::IntegrationTest
  test "returns bad_request for invalid signature" do
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test"

    post webhooks_stripe_path,
         params: "{}",
         headers: { "HTTP_STRIPE_SIGNATURE" => "invalid", "CONTENT_TYPE" => "application/json" }

    assert_response :bad_request
  end

  test "returns bad_request for malformed JSON" do
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test"

    post webhooks_stripe_path,
         params: "not json at all",
         headers: { "HTTP_STRIPE_SIGNATURE" => "invalid", "CONTENT_TYPE" => "application/json" }

    assert_response :bad_request
  end
end
