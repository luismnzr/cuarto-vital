require "test_helper"

class Admin::WellhubBookingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:user, :admin)
    @studio_class = create(:studio_class)
    @booking = create(:wellhub_booking, studio_class: @studio_class)
    sign_in @admin
  end

  test "index returns CSV when requested" do
    get admin_wellhub_bookings_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "Booking Number"
    assert_includes response.body, @booking.booking_number
    assert_includes response.body, @booking.gympass_id
  end

  test "index CSV filters by status" do
    cancelled = create(:wellhub_booking, :cancelled, studio_class: @studio_class)

    get admin_wellhub_bookings_path(format: :csv, status: "cancelled")
    assert_response :success
    assert_includes response.body, cancelled.booking_number
  end

  test "redirects non-admin users" do
    sign_out @admin
    student = create(:user, :student)
    sign_in student

    get admin_wellhub_bookings_path
    assert_response :redirect
  end

  test "redirects unauthenticated users" do
    sign_out @admin

    get admin_wellhub_bookings_path
    assert_response :redirect
  end

  test "show redirects unauthenticated users" do
    sign_out @admin

    get admin_wellhub_booking_path(@booking)
    assert_response :redirect
  end
end
