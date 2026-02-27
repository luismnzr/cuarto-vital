require "test_helper"

class StudioClassWellhubTest < ActiveSupport::TestCase
  setup do
    @studio_class = create(:studio_class, wellhub_slot_id: "slot_test")
    StudioSetting.set("wellhub_gym_id", "gym_test")
  end

  test "cancelling class cancels active wellhub bookings" do
    accepted = create(:wellhub_booking,
      studio_class: @studio_class,
      booking_number: "WH-ACTIVE",
      status: "accepted"
    )
    already_cancelled = create(:wellhub_booking, :cancelled,
      studio_class: @studio_class,
      booking_number: "WH-DONE"
    )

    api_stub = ->(**_kwargs) { nil }
    WellhubClient.stub(:update_booking, api_stub) do
      @studio_class.update!(status: "cancelled")
    end

    assert_equal "cancelled", accepted.reload.status
    assert_not_nil accepted.cancelled_at
    # Already cancelled booking should remain unchanged
    assert_equal "cancelled", already_cancelled.reload.status
  end

  test "cancelling class does not affect class without wellhub_slot_id" do
    plain_class = create(:studio_class, wellhub_slot_id: nil)
    booking = create(:wellhub_booking,
      studio_class: plain_class,
      booking_number: "WH-PLAIN",
      status: "accepted"
    )

    plain_class.update!(status: "cancelled")

    # Callback should skip since no wellhub_slot_id
    assert_equal "accepted", booking.reload.status
  end

  test "updating non-status fields does not trigger cancellation" do
    booking = create(:wellhub_booking,
      studio_class: @studio_class,
      booking_number: "WH-NO-CANCEL",
      status: "accepted"
    )

    @studio_class.update!(capacity: 30)

    assert_equal "accepted", booking.reload.status
  end
end
