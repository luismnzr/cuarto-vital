require "test_helper"

class WaitlistServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @package = create(:package, credit_count: 5, expiration_days: 30)
    @user_package = create(:user_package, user: @user, package: @package, credits_remaining: 5)
    @studio_class = create(:studio_class, :full, capacity: 10)
    StudioSetting.set("waitlist_enabled", "true")
    StudioSetting.set("max_waitlist_size", "5")
  end

  test "join adds user to waitlist with correct position" do
    result = WaitlistService.join(user: @user, studio_class: @studio_class)

    assert result.success?
    assert_equal 1, result.entry.position
    assert_equal "pending", result.entry.status
  end

  test "join fails when class is not full" do
    @studio_class.update!(spots_remaining: 5)

    result = WaitlistService.join(user: @user, studio_class: @studio_class)

    assert_not result.success?
    assert_match(/not full/, result.error)
  end

  test "join fails when waitlist is disabled" do
    StudioSetting.set("waitlist_enabled", "false")

    result = WaitlistService.join(user: @user, studio_class: @studio_class)

    assert_not result.success?
    assert_match(/not enabled/, result.error)
  end

  test "join fails when waitlist is full" do
    StudioSetting.set("max_waitlist_size", "1")
    other_user = create(:user)
    create(:waitlist_entry, user: other_user, studio_class: @studio_class, position: 1, joined_at: Time.current, status: "pending")

    result = WaitlistService.join(user: @user, studio_class: @studio_class)

    assert_not result.success?
    assert_match(/waitlist is full/, result.error)
  end

  test "join fails when user is already on waitlist" do
    create(:waitlist_entry, user: @user, studio_class: @studio_class, position: 1, joined_at: Time.current, status: "pending")

    result = WaitlistService.join(user: @user, studio_class: @studio_class)

    assert_not result.success?
    assert_match(/already on the waitlist/, result.error)
  end

  test "leave removes user from waitlist" do
    entry = create(:waitlist_entry, user: @user, studio_class: @studio_class, position: 1, joined_at: Time.current, status: "pending")

    result = WaitlistService.leave(entry: entry)

    assert result.success?
    assert_equal "cancelled", entry.reload.status
  end

  test "promote_next promotes first pending user and creates reservation" do
    # Free up a spot
    @studio_class.update!(spots_remaining: 1)

    entry = create(:waitlist_entry, user: @user, studio_class: @studio_class, position: 1, joined_at: Time.current, status: "pending")

    result = WaitlistService.promote_next(studio_class: @studio_class)

    assert_equal "promoted", entry.reload.status
    assert_equal 1, @user.reservations.confirmed.where(studio_class: @studio_class).count
    assert_equal 0, @studio_class.reload.spots_remaining
  end

  test "promote_next skips user who can no longer reserve" do
    @studio_class.update!(spots_remaining: 1)

    # User with no credits
    no_credit_user = create(:user)
    entry1 = create(:waitlist_entry, user: no_credit_user, studio_class: @studio_class, position: 1, joined_at: 1.hour.ago, status: "pending")
    entry2 = create(:waitlist_entry, user: @user, studio_class: @studio_class, position: 2, joined_at: Time.current, status: "pending")

    WaitlistService.promote_next(studio_class: @studio_class)

    assert_equal "expired", entry1.reload.status
    assert_equal "promoted", entry2.reload.status
  end
end
