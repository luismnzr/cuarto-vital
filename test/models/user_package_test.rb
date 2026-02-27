require "test_helper"

class UserPackageTest < ActiveSupport::TestCase
  test "use_credit! decrements credits" do
    user_package = create(:user_package, credits_remaining: 5)
    user_package.use_credit!
    assert_equal 4, user_package.reload.credits_remaining
  end

  test "use_credit! raises when depleted" do
    user_package = create(:user_package, credits_remaining: 0, status: "depleted")
    assert_raises(RuntimeError) { user_package.use_credit! }
  end

  test "use_credit! raises when expired" do
    user_package = create(:user_package, expires_at: 1.day.ago)
    assert_raises(RuntimeError) { user_package.use_credit! }
  end

  test "use_credit! sets status to depleted when last credit used" do
    user_package = create(:user_package, credits_remaining: 1)
    user_package.use_credit!
    assert_equal "depleted", user_package.reload.status
  end

  test "restore_credit! increments credits" do
    user_package = create(:user_package, credits_remaining: 4)
    credit = create(:class_credit, user_package: user_package, used_at: Time.current)
    user_package.restore_credit!(credit)
    assert_equal 5, user_package.reload.credits_remaining
  end
end
