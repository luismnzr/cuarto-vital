require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = build(:user)
    assert user.valid?
  end

  test "requires first_name" do
    user = build(:user, first_name: nil)
    assert_not user.valid?
  end

  test "requires last_name" do
    user = build(:user, last_name: nil)
    assert_not user.valid?
  end

  test "requires unique email" do
    create(:user, email: "test@example.com")
    user = build(:user, email: "test@example.com")
    assert_not user.valid?
  end

  test "full_name returns combined name" do
    user = build(:user, first_name: "Jane", last_name: "Doe")
    assert_equal "Jane Doe", user.full_name
  end

  test "role enum works" do
    assert build(:user, role: :student).student?
    assert build(:user, role: :teacher).teacher?
    assert build(:user, role: :admin).admin?
  end

  test "can_reserve? with active package" do
    user = create(:user)
    create(:user_package, user: user, credits_remaining: 5, expires_at: 30.days.from_now)
    assert user.can_reserve?
  end

  test "can_reserve? with active subscription" do
    user = create(:user)
    create(:user_subscription, user: user, status: "active", current_period_end: 1.month.from_now)
    assert user.can_reserve?
  end

  test "cannot reserve without credits or subscription" do
    user = create(:user)
    assert_not user.can_reserve?
  end
end
