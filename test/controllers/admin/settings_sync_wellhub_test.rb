require "test_helper"

class Admin::SettingsSyncWellhubTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  test "sync_wellhub redirects with notice when wellhub is enabled" do
    StudioSetting.set("wellhub_enabled", "true")

    WellhubScheduleSyncJob.stub(:perform_later, nil) do
      post admin_sync_wellhub_path
    end

    assert_redirected_to admin_settings_path
    assert_includes flash[:notice], "sync started"
  end

  test "sync_wellhub redirects with alert when wellhub is disabled" do
    StudioSetting.set("wellhub_enabled", "false")

    post admin_sync_wellhub_path
    assert_redirected_to admin_settings_path
    assert_equal "Wellhub integration is not enabled.", flash[:alert]
  end

  test "sync_wellhub redirects non-admin users" do
    sign_out @admin
    student = create(:user, :student)
    sign_in student

    post admin_sync_wellhub_path
    assert_response :redirect
  end
end
