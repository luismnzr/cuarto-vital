require "test_helper"

class Webhooks::WellhubControllerTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test_webhook_secret_123"
    ENV["WELLHUB_WEBHOOK_SECRET"] = @secret
    ENV["WELLHUB_API_KEY"] = "test_api_key"
  end

  test "returns unauthorized when signature header is missing" do
    post webhooks_wellhub_path,
         params: '{"event":"checkin"}',
         headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :unauthorized
  end

  test "returns unauthorized when signature is invalid" do
    post webhooks_wellhub_path,
         params: '{"event":"checkin"}',
         headers: {
           "CONTENT_TYPE" => "application/json",
           "X-Gympass-Signature" => "deadbeef"
         }

    assert_response :unauthorized
  end

  test "returns ok with valid lowercase signature" do
    body = '{"event":"checkin","gympass_id":"gpw_test"}'
    signature = OpenSSL::HMAC.hexdigest("sha1", @secret, body).downcase

    WellhubCheckinService.stub(:process, nil) do
      post webhooks_wellhub_path,
           params: body,
           headers: {
             "CONTENT_TYPE" => "application/json",
             "X-Gympass-Signature" => signature
           }
    end

    assert_response :ok
  end

  test "returns ok with valid uppercase signature" do
    body = '{"event":"checkin","gympass_id":"gpw_test"}'
    signature = OpenSSL::HMAC.hexdigest("sha1", @secret, body).upcase

    WellhubCheckinService.stub(:process, nil) do
      post webhooks_wellhub_path,
           params: body,
           headers: {
             "CONTENT_TYPE" => "application/json",
             "X-Gympass-Signature" => signature
           }
    end

    assert_response :ok
  end

  test "routes checkin event to WellhubCheckinService" do
    body = '{"event":"checkin","gympass_id":"gpw_test"}'
    signature = sign(body)

    called = false
    WellhubCheckinService.stub(:process, ->(_payload) { called = true }) do
      post webhooks_wellhub_path,
           params: body,
           headers: signed_headers(body)
    end

    assert_response :ok
    assert called, "WellhubCheckinService.process should have been called"
  end

  test "routes booking-requested event to WellhubBookingService" do
    body = '{"event":"booking-requested","booking_number":"WH-123","slot_id":"slot_1"}'
    signature = sign(body)

    called = false
    WellhubBookingService.stub(:booking_requested, ->(_payload) { called = true }) do
      post webhooks_wellhub_path,
           params: body,
           headers: signed_headers(body)
    end

    assert_response :ok
    assert called, "WellhubBookingService.booking_requested should have been called"
  end

  test "routes booking-cancelled event to WellhubBookingService" do
    body = '{"event":"booking-cancelled","booking_number":"WH-123"}'

    called = false
    WellhubBookingService.stub(:booking_cancelled, ->(_payload) { called = true }) do
      post webhooks_wellhub_path,
           params: body,
           headers: signed_headers(body)
    end

    assert_response :ok
    assert called
  end

  test "routes booking-checked-in event to WellhubBookingService" do
    body = '{"event":"booking-checked-in","booking_number":"WH-123"}'

    called = false
    WellhubBookingService.stub(:booking_checked_in, ->(_payload) { called = true }) do
      post webhooks_wellhub_path,
           params: body,
           headers: signed_headers(body)
    end

    assert_response :ok
    assert called
  end

  test "returns bad_request for malformed JSON with valid signature" do
    body = "not json"
    post webhooks_wellhub_path,
         params: body,
         headers: signed_headers(body)

    assert_response :bad_request
  end

  test "returns ok for unknown event type" do
    body = '{"event":"unknown-event"}'

    post webhooks_wellhub_path,
         params: body,
         headers: signed_headers(body)

    assert_response :ok
  end

  private

  def sign(body)
    OpenSSL::HMAC.hexdigest("sha1", @secret, body)
  end

  def signed_headers(body)
    {
      "CONTENT_TYPE" => "application/json",
      "X-Gympass-Signature" => sign(body)
    }
  end
end
