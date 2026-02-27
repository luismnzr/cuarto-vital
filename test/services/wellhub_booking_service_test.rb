require "test_helper"

class WellhubBookingServiceTest < ActiveSupport::TestCase
  setup do
    @studio_class = create(:studio_class, spots_remaining: 5, capacity: 20, wellhub_slot_id: "slot_abc")
    StudioSetting.set("wellhub_gym_id", "gym_test")
    StudioSetting.set("wellhub_enabled", "true")

    # Stub all outbound API calls
    @api_stub = ->(*_args, **_kwargs) { nil }
  end

  # --- booking_requested ---

  test "booking_requested accepts booking when spots available" do
    payload = booking_requested_payload

    WellhubClient.stub(:update_booking, @api_stub) do
      WellhubClient.stub(:update_slot, @api_stub) do
        WellhubBookingService.booking_requested(payload)
      end
    end

    booking = WellhubBooking.find_by(booking_number: "WH-001")
    assert_not_nil booking
    assert_equal "accepted", booking.status
    assert_equal "gpw_user1", booking.gympass_id
    assert_equal 4, @studio_class.reload.spots_remaining
  end

  test "booking_requested rejects booking when class is full" do
    @studio_class.update!(spots_remaining: 0)
    payload = booking_requested_payload

    WellhubClient.stub(:update_booking, @api_stub) do
      WellhubBookingService.booking_requested(payload)
    end

    booking = WellhubBooking.find_by(booking_number: "WH-001")
    assert_not_nil booking
    assert_equal "rejected", booking.status
    assert_equal 0, @studio_class.reload.spots_remaining
  end

  test "booking_requested rejects booking when class is cancelled" do
    @studio_class.update!(status: "cancelled")
    payload = booking_requested_payload

    WellhubClient.stub(:update_booking, @api_stub) do
      WellhubBookingService.booking_requested(payload)
    end

    booking = WellhubBooking.find_by(booking_number: "WH-001")
    assert_equal "rejected", booking.status
  end

  test "booking_requested rejects booking for unknown slot" do
    payload = booking_requested_payload(slot_id: "nonexistent_slot")

    WellhubClient.stub(:update_booking, @api_stub) do
      WellhubBookingService.booking_requested(payload)
    end

    assert_equal 0, WellhubBooking.count
  end

  test "booking_requested is idempotent — skips duplicate booking_number" do
    create(:wellhub_booking, studio_class: @studio_class, booking_number: "WH-001", gympass_id: "gpw_user1")
    payload = booking_requested_payload

    WellhubClient.stub(:update_booking, @api_stub) do
      WellhubClient.stub(:update_slot, @api_stub) do
        WellhubBookingService.booking_requested(payload)
      end
    end

    assert_equal 1, WellhubBooking.where(booking_number: "WH-001").count
    assert_equal 5, @studio_class.reload.spots_remaining # unchanged
  end

  test "booking_requested decrements spots_remaining exactly once" do
    payload = booking_requested_payload

    WellhubClient.stub(:update_booking, @api_stub) do
      WellhubClient.stub(:update_slot, @api_stub) do
        WellhubBookingService.booking_requested(payload)
      end
    end

    assert_equal 4, @studio_class.reload.spots_remaining
  end

  # --- booking_cancelled ---

  test "booking_cancelled frees spot and updates status" do
    booking = create(:wellhub_booking,
      studio_class: @studio_class,
      booking_number: "WH-CANCEL-1",
      gympass_id: "gpw_user1",
      status: "accepted"
    )
    @studio_class.update!(spots_remaining: 4)

    WellhubClient.stub(:update_slot, @api_stub) do
      WellhubBookingService.booking_cancelled({ "booking_number" => "WH-CANCEL-1" })
    end

    assert_equal "cancelled", booking.reload.status
    assert_equal 5, @studio_class.reload.spots_remaining
  end

  test "booking_cancelled does not increment spots above capacity" do
    booking = create(:wellhub_booking,
      studio_class: @studio_class,
      booking_number: "WH-CANCEL-2",
      gympass_id: "gpw_user1",
      status: "accepted"
    )
    @studio_class.update!(spots_remaining: 20) # already at capacity

    WellhubClient.stub(:update_slot, @api_stub) do
      WellhubBookingService.booking_cancelled({ "booking_number" => "WH-CANCEL-2" })
    end

    assert_equal "cancelled", booking.reload.status
    assert_equal 20, @studio_class.reload.spots_remaining # capped at capacity
  end

  test "booking_cancelled ignores already cancelled booking" do
    create(:wellhub_booking, :cancelled,
      studio_class: @studio_class,
      booking_number: "WH-CANCEL-3",
      gympass_id: "gpw_user1"
    )

    WellhubBookingService.booking_cancelled({ "booking_number" => "WH-CANCEL-3" })

    assert_equal 5, @studio_class.reload.spots_remaining # unchanged
  end

  test "booking_cancelled ignores unknown booking number" do
    WellhubBookingService.booking_cancelled({ "booking_number" => "WH-GHOST" })

    # Should not raise, just log a warning
    assert_equal 5, @studio_class.reload.spots_remaining
  end

  # --- booking_checked_in ---

  test "booking_checked_in marks booking and creates external checkin" do
    booking = create(:wellhub_booking,
      studio_class: @studio_class,
      booking_number: "WH-CHECKIN-1",
      gympass_id: "gpw_user1",
      status: "accepted"
    )

    assert_difference "ExternalCheckin.count", 1 do
      WellhubBookingService.booking_checked_in({ "booking_number" => "WH-CHECKIN-1" })
    end

    assert_equal "checked_in", booking.reload.status

    checkin = ExternalCheckin.last
    assert_equal "gpw_user1", checkin.user_identifier
    assert_equal "wellhub", checkin.platform
    assert_equal @studio_class, checkin.studio_class
    assert checkin.validated
    assert_equal "WH-CHECKIN-1", checkin.external_reference_id
  end

  test "booking_checked_in is idempotent — does not duplicate checkin" do
    booking = create(:wellhub_booking,
      studio_class: @studio_class,
      booking_number: "WH-CHECKIN-2",
      gympass_id: "gpw_user1",
      status: "accepted"
    )

    WellhubBookingService.booking_checked_in({ "booking_number" => "WH-CHECKIN-2" })
    WellhubBookingService.booking_checked_in({ "booking_number" => "WH-CHECKIN-2" })

    assert_equal 1, ExternalCheckin.where(user_identifier: "gpw_user1", studio_class: @studio_class).count
  end

  test "booking_checked_in ignores unknown booking" do
    assert_no_difference "ExternalCheckin.count" do
      WellhubBookingService.booking_checked_in({ "booking_number" => "WH-GHOST" })
    end
  end

  private

  def booking_requested_payload(slot_id: "slot_abc", booking_number: "WH-001")
    {
      "booking_number" => booking_number,
      "gympass_id" => "gpw_user1",
      "slot_id" => slot_id,
      "gym_id" => "gym_test"
    }
  end
end
