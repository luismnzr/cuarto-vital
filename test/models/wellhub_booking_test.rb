require "test_helper"

class WellhubBookingTest < ActiveSupport::TestCase
  setup do
    @studio_class = create(:studio_class)
  end

  test "valid booking" do
    booking = build(:wellhub_booking, studio_class: @studio_class)
    assert booking.valid?
  end

  test "requires booking_number" do
    booking = build(:wellhub_booking, studio_class: @studio_class, booking_number: nil)
    assert_not booking.valid?
    assert_includes booking.errors[:booking_number], "can't be blank"
  end

  test "requires unique booking_number" do
    create(:wellhub_booking, studio_class: @studio_class, booking_number: "WH-DUP")
    booking = build(:wellhub_booking, studio_class: @studio_class, booking_number: "WH-DUP")
    assert_not booking.valid?
    assert_includes booking.errors[:booking_number], "has already been taken"
  end

  test "requires gympass_id" do
    booking = build(:wellhub_booking, studio_class: @studio_class, gympass_id: nil)
    assert_not booking.valid?
  end

  test "requires booked_at" do
    booking = build(:wellhub_booking, studio_class: @studio_class, booked_at: nil)
    assert_not booking.valid?
  end

  test "validates status inclusion" do
    booking = build(:wellhub_booking, studio_class: @studio_class, status: "unknown")
    assert_not booking.valid?
    assert_includes booking.errors[:status], "is not included in the list"
  end

  test "all valid statuses are accepted" do
    %w[pending accepted rejected cancelled checked_in].each do |status|
      booking = build(:wellhub_booking, studio_class: @studio_class, status: status)
      assert booking.valid?, "Status '#{status}' should be valid"
    end
  end

  test "accept! sets status and responded_at" do
    booking = create(:wellhub_booking, :pending, studio_class: @studio_class)
    booking.accept!
    assert_equal "accepted", booking.status
    assert_not_nil booking.responded_at
  end

  test "reject! sets status and responded_at" do
    booking = create(:wellhub_booking, :pending, studio_class: @studio_class)
    booking.reject!
    assert_equal "rejected", booking.status
    assert_not_nil booking.responded_at
  end

  test "cancel! sets status and cancelled_at" do
    booking = create(:wellhub_booking, studio_class: @studio_class)
    booking.cancel!
    assert_equal "cancelled", booking.status
    assert_not_nil booking.cancelled_at
  end

  test "check_in! sets status and checked_in_at" do
    booking = create(:wellhub_booking, studio_class: @studio_class)
    booking.check_in!
    assert_equal "checked_in", booking.status
    assert_not_nil booking.checked_in_at
  end

  test "active scope returns pending and accepted" do
    pending = create(:wellhub_booking, :pending, studio_class: @studio_class, booking_number: "WH-P")
    accepted = create(:wellhub_booking, studio_class: @studio_class, booking_number: "WH-A")
    create(:wellhub_booking, :cancelled, studio_class: @studio_class, booking_number: "WH-C")
    create(:wellhub_booking, :checked_in, studio_class: @studio_class, booking_number: "WH-CI")

    active = WellhubBooking.active
    assert_includes active, pending
    assert_includes active, accepted
    assert_equal 2, active.count
  end

  test "accepted scope returns only accepted" do
    create(:wellhub_booking, :pending, studio_class: @studio_class, booking_number: "WH-P2")
    accepted = create(:wellhub_booking, studio_class: @studio_class, booking_number: "WH-A2")

    assert_equal [accepted], WellhubBooking.accepted.to_a
  end
end
