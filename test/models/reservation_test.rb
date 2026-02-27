require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  test "valid reservation" do
    reservation = build(:reservation)
    assert reservation.valid?
  end

  test "prevents duplicate reservation for same user and class" do
    studio_class = create(:studio_class)
    user = create(:user)
    create(:reservation, user: user, studio_class: studio_class)
    duplicate = build(:reservation, user: user, studio_class: studio_class)
    assert_not duplicate.valid?
  end

  test "cancel! sets status and timestamp" do
    reservation = create(:reservation)
    reservation.cancel!
    assert_equal "cancelled", reservation.status
    assert_not_nil reservation.cancelled_at
  end

  test "late cancel sets late_cancel flag" do
    reservation = create(:reservation)
    reservation.cancel!(late: true)
    assert reservation.late_cancel
  end
end
