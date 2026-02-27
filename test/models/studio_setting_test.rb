require "test_helper"

class StudioSettingTest < ActiveSupport::TestCase
  test "get returns default when not set" do
    assert_equal "Studio", StudioSetting.get("studio_name")
  end

  test "set and get" do
    StudioSetting.set("studio_name", "Test Studio")
    assert_equal "Test Studio", StudioSetting.get("studio_name")
  end

  test "key must be unique" do
    StudioSetting.create!(key: "test_key", value: "value1")
    duplicate = StudioSetting.new(key: "test_key", value: "value2")
    assert_not duplicate.valid?
  end
end
