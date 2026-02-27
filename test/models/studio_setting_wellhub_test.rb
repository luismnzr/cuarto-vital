require "test_helper"

class StudioSettingWellhubTest < ActiveSupport::TestCase
  test "set rejects unknown keys" do
    StudioSetting.set("malicious_key", "bad_value")
    assert_nil StudioSetting.find_by(key: "malicious_key")
  end

  test "set accepts known keys" do
    StudioSetting.set("wellhub_enabled", "true")
    assert_equal "true", StudioSetting.get("wellhub_enabled")
  end

  test "wellhub_enabled? returns false by default" do
    assert_not StudioSetting.wellhub_enabled?
  end

  test "wellhub_enabled? returns true when set" do
    StudioSetting.set("wellhub_enabled", "true")
    assert StudioSetting.wellhub_enabled?
  end

  test "wellhub_gym_id falls back to ENV" do
    ENV["WELLHUB_GYM_ID"] = "env_gym_123"
    assert_equal "env_gym_123", StudioSetting.wellhub_gym_id
  ensure
    ENV.delete("WELLHUB_GYM_ID")
  end

  test "wellhub_gym_id prefers database value over ENV" do
    ENV["WELLHUB_GYM_ID"] = "env_gym"
    StudioSetting.set("wellhub_gym_id", "db_gym")
    assert_equal "db_gym", StudioSetting.wellhub_gym_id
  ensure
    ENV.delete("WELLHUB_GYM_ID")
  end

  test "wellhub_gym_id returns nil when neither set" do
    ENV.delete("WELLHUB_GYM_ID")
    assert_nil StudioSetting.wellhub_gym_id
  end

  test "ALLOWED_KEYS includes all DEFAULTS keys" do
    assert_equal StudioSetting::DEFAULTS.keys, StudioSetting::ALLOWED_KEYS
  end
end
