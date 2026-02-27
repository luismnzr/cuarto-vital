require "test_helper"

class ReservationServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @package = create(:package, credit_count: 5, expiration_days: 30)
    @user_package = create(:user_package, user: @user, package: @package, credits_remaining: 5)
    @studio_class = create(:studio_class, spots_remaining: 10, capacity: 10)
  end

  test "reserve with credits deducts credit and creates reservation" do
    result = ReservationService.reserve(user: @user, studio_class: @studio_class)

    assert result.success?
    assert_equal "confirmed", result.reservation.status
    assert_equal 4, @user_package.reload.credits_remaining
    assert_equal 9, @studio_class.reload.spots_remaining
    assert_not_nil result.reservation.class_credit
  end

  test "reserve with subscription does not deduct credits" do
    plan = create(:subscription_plan)
    create(:user_subscription, user: @user, subscription_plan: plan, status: "active",
           current_period_end: 30.days.from_now)

    result = ReservationService.reserve(user: @user, studio_class: @studio_class)

    assert result.success?
    assert_equal 5, @user_package.reload.credits_remaining # unchanged
    assert_nil result.reservation.class_credit
  end

  test "reserve fails when class is full" do
    @studio_class.update!(spots_remaining: 0)

    result = ReservationService.reserve(user: @user, studio_class: @studio_class)

    assert_not result.success?
    assert_equal "This class is full", result.error
  end

  test "reserve fails when user has no credits or subscription" do
    @user_package.update!(credits_remaining: 0, status: "depleted")

    result = ReservationService.reserve(user: @user, studio_class: @studio_class)

    assert_not result.success?
    assert_match(/need an active package/, result.error)
  end

  test "reserve fails with duplicate reservation" do
    create(:reservation, user: @user, studio_class: @studio_class, status: "confirmed")

    result = ReservationService.reserve(user: @user, studio_class: @studio_class)

    assert_not result.success?
    assert_match(/already have a reservation/, result.error)
  end

  test "cancel restores credit and increments spots" do
    # Ensure class is far enough in the future to avoid late-cancel window
    @studio_class.update!(date: Date.current + 7.days)

    result = ReservationService.reserve(user: @user, studio_class: @studio_class)
    reservation = result.reservation

    cancel_result = ReservationService.cancel(reservation: reservation)

    assert cancel_result.success?
    assert_equal "cancelled", reservation.reload.status
    assert_equal 5, @user_package.reload.credits_remaining
    assert_equal 10, @studio_class.reload.spots_remaining
  end

  test "late cancel forfeits credit when setting enabled" do
    # Set class to start tomorrow (future, so reservation succeeds) but
    # use a wide cancellation window so cancelling now counts as late
    @studio_class.update!(date: Date.tomorrow, start_time: Time.zone.parse("09:00"), end_time: Time.zone.parse("10:00"))
    StudioSetting.set("cancellation_window_hours", "48")
    StudioSetting.set("late_cancel_forfeit_credit", "true")

    result = ReservationService.reserve(user: @user, studio_class: @studio_class)
    reservation = result.reservation

    cancel_result = ReservationService.cancel(reservation: reservation)

    assert cancel_result.success?
    assert reservation.reload.late_cancel?
    # Credit should NOT be restored (forfeited)
    assert_equal 4, @user_package.reload.credits_remaining
  end
end
