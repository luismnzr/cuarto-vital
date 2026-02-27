require "test_helper"

class StudioClassTest < ActiveSupport::TestCase
  test "valid studio class" do
    studio_class = build(:studio_class)
    assert studio_class.valid?
  end

  test "full? when spots_remaining is 0" do
    studio_class = build(:studio_class, spots_remaining: 0)
    assert studio_class.full?
  end

  test "not full? when spots remain" do
    studio_class = build(:studio_class, spots_remaining: 5)
    assert_not studio_class.full?
  end

  test "delegates name to class_template" do
    template = build(:class_template, name: "Test Class")
    studio_class = build(:studio_class, class_template: template)
    assert_equal "Test Class", studio_class.name
  end
end
