require "test_helper"

class WellhubSetupServiceTest < ActiveSupport::TestCase
  setup do
    ENV["APP_HOST"] = "https://studio.example.com"
    @api_stub = ->(**_kwargs) { nil }
  end

  teardown do
    ENV.delete("APP_HOST")
  end

  test "integration_requested stores gym_id when not already set" do
    payload = { "gym_id" => "gym_new_42" }

    WellhubClient.stub(:register_webhooks, @api_stub) do
      WellhubSetupService.integration_requested(payload)
    end

    assert_equal "gym_new_42", StudioSetting.get("wellhub_gym_id")
  end

  test "integration_requested does not overwrite existing gym_id" do
    StudioSetting.set("wellhub_gym_id", "gym_existing")
    payload = { "gym_id" => "gym_existing" }

    WellhubClient.stub(:register_webhooks, @api_stub) do
      WellhubSetupService.integration_requested(payload)
    end

    assert_equal "gym_existing", StudioSetting.get("wellhub_gym_id")
  end

  test "integration_requested returns early when gym_id conflicts" do
    StudioSetting.set("wellhub_gym_id", "gym_original")
    payload = { "gym_id" => "gym_different" }

    webhook_called = false
    mock_register = ->(**_kwargs) { webhook_called = true }

    WellhubClient.stub(:register_webhooks, mock_register) do
      WellhubSetupService.integration_requested(payload)
    end

    # Should NOT register webhooks for a conflicting gym_id
    assert_not webhook_called
    # Should keep the original gym_id
    assert_equal "gym_original", StudioSetting.get("wellhub_gym_id")
  end

  test "integration_requested registers webhooks with correct URLs" do
    payload = { "gym_id" => "gym_42" }

    captured_webhooks = nil
    captured_gym_id = nil
    mock_register = ->(gym_id:, webhooks:) {
      captured_gym_id = gym_id
      captured_webhooks = webhooks
      nil
    }

    WellhubClient.stub(:register_webhooks, mock_register) do
      WellhubSetupService.integration_requested(payload)
    end

    assert_equal "gym_42", captured_gym_id

    # Per WellHub docs: register checkin, booking-requested, booking-cancelled, booking-checked-in
    events = captured_webhooks.map { |wh| wh[:event] }
    assert_includes events, "checkin"
    assert_includes events, "booking-requested"
    assert_includes events, "booking-cancelled"
    assert_includes events, "booking-checked-in"

    # All webhooks should point to our single endpoint
    captured_webhooks.each do |wh|
      assert_equal "https://studio.example.com/webhooks/wellhub", wh[:url]
    end
  end

  test "integration_requested handles API error gracefully" do
    payload = { "gym_id" => "gym_error" }

    mock_register = ->(**_kwargs) {
      raise WellhubClient::Error.new("Connection refused", status: 503)
    }

    WellhubClient.stub(:register_webhooks, mock_register) do
      # Should not raise — error is rescued and logged
      WellhubSetupService.integration_requested(payload)
    end

    # gym_id should still be stored even though webhook registration failed
    assert_equal "gym_error", StudioSetting.get("wellhub_gym_id")
  end

  test "integration_requested does not enable wellhub automatically" do
    payload = { "gym_id" => "gym_auto" }

    WellhubClient.stub(:register_webhooks, @api_stub) do
      WellhubSetupService.integration_requested(payload)
    end

    # Admin must manually enable from settings
    assert_not StudioSetting.wellhub_enabled?
  end

  test "integration_requested uses HEROKU_APP_NAME fallback when APP_HOST not set" do
    ENV.delete("APP_HOST")
    ENV["HEROKU_APP_NAME"] = "eclipse-studio-prod"
    payload = { "gym_id" => "gym_heroku" }

    captured_webhooks = nil
    mock_register = ->(gym_id:, webhooks:) {
      captured_webhooks = webhooks
      nil
    }

    WellhubClient.stub(:register_webhooks, mock_register) do
      WellhubSetupService.integration_requested(payload)
    end

    captured_webhooks.each do |wh|
      assert_equal "https://eclipse-studio-prod.herokuapp.com/webhooks/wellhub", wh[:url]
    end
  ensure
    ENV.delete("HEROKU_APP_NAME")
  end

  test "integration_requested prepends https when APP_HOST is a bare hostname" do
    ENV["APP_HOST"] = "app.mystudio.com"
    payload = { "gym_id" => "gym_bare" }

    captured_webhooks = nil
    mock_register = ->(gym_id:, webhooks:) {
      captured_webhooks = webhooks
      nil
    }

    WellhubClient.stub(:register_webhooks, mock_register) do
      WellhubSetupService.integration_requested(payload)
    end

    captured_webhooks.each do |wh|
      assert_equal "https://app.mystudio.com/webhooks/wellhub", wh[:url]
    end
  end

  test "integration_requested raises when neither APP_HOST nor HEROKU_APP_NAME is set" do
    ENV.delete("APP_HOST")
    ENV.delete("HEROKU_APP_NAME")
    payload = { "gym_id" => "gym_nohost" }

    assert_raises(RuntimeError, "APP_HOST must be set to register Wellhub webhooks") do
      WellhubSetupService.integration_requested(payload)
    end
  end
end
