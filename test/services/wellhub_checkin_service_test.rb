require "test_helper"

class WellhubCheckinServiceTest < ActiveSupport::TestCase
  setup do
    @studio_class = create(:studio_class, :today, wellhub_slot_id: "slot_abc")
    StudioSetting.set("wellhub_gym_id", "gym_test")
    StudioSetting.set("wellhub_enabled", "true")
  end

  test "process validates checkin and creates external checkin record" do
    payload = { "gympass_id" => "gpw_user1", "gym_id" => "gym_test", "checkin_id" => "ck_123" }

    WellhubClient.stub(:validate_checkin, nil) do
      assert_difference "ExternalCheckin.count", 1 do
        WellhubCheckinService.process(payload)
      end
    end

    checkin = ExternalCheckin.last
    assert_equal "gpw_user1", checkin.user_identifier
    assert_equal "wellhub", checkin.platform
    assert checkin.validated
    assert_equal "ck_123", checkin.external_reference_id
  end

  test "process prefers user's booked class over time-based match" do
    # Create another class today that would match time-based fallback
    other_class = create(:studio_class, :today)

    # User has a booking for our specific class
    booking = create(:wellhub_booking,
      studio_class: @studio_class,
      gympass_id: "gpw_booked",
      status: "accepted"
    )

    payload = { "gympass_id" => "gpw_booked", "gym_id" => "gym_test" }

    WellhubClient.stub(:validate_checkin, nil) do
      WellhubCheckinService.process(payload)
    end

    checkin = ExternalCheckin.last
    assert_equal @studio_class, checkin.studio_class
    assert_equal "checked_in", booking.reload.status
  end

  test "process marks matching booking as checked in" do
    booking = create(:wellhub_booking,
      studio_class: @studio_class,
      gympass_id: "gpw_user1",
      status: "accepted"
    )

    payload = { "gympass_id" => "gpw_user1", "gym_id" => "gym_test" }

    WellhubClient.stub(:validate_checkin, nil) do
      WellhubCheckinService.process(payload)
    end

    assert_equal "checked_in", booking.reload.status
  end

  test "process does not create duplicate checkins on retry" do
    payload = { "gympass_id" => "gpw_user1", "gym_id" => "gym_test" }

    WellhubClient.stub(:validate_checkin, nil) do
      WellhubCheckinService.process(payload)
      WellhubCheckinService.process(payload)
    end

    assert_equal 1, ExternalCheckin.where(user_identifier: "gpw_user1", studio_class: @studio_class).count
  end

  test "process returns early when gympass_id is missing" do
    payload = { "gym_id" => "gym_test" }

    assert_no_difference "ExternalCheckin.count" do
      WellhubCheckinService.process(payload)
    end
  end

  test "process returns early when Wellhub validation fails" do
    payload = { "gympass_id" => "gpw_user1", "gym_id" => "gym_test" }

    error = WellhubClient::Error.new("Unauthorized", status: 401)
    raise_error = ->(**_kwargs) { raise error }

    WellhubClient.stub(:validate_checkin, raise_error) do
      assert_no_difference "ExternalCheckin.count" do
        WellhubCheckinService.process(payload)
      end
    end
  end

  test "process handles user.unique_token payload format" do
    payload = {
      "user" => { "unique_token" => "gpw_token_user" },
      "gym_id" => "gym_test"
    }

    WellhubClient.stub(:validate_checkin, nil) do
      WellhubCheckinService.process(payload)
    end

    checkin = ExternalCheckin.last
    assert_equal "gpw_token_user", checkin.user_identifier
  end
end
