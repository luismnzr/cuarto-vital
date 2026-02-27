require "test_helper"

class WellhubBookingMailerTest < ActionMailer::TestCase
  setup do
    @studio_class = create(:studio_class)
    @booking = create(:wellhub_booking, studio_class: @studio_class)
    StudioSetting.set("studio_email", "admin@studio.test")
  end

  test "new_booking sends email to admin" do
    email = WellhubBookingMailer.new_booking(@booking)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["admin@studio.test"], email.to
    assert_includes email.subject, "New Wellhub Booking"
    assert_includes email.subject, @studio_class.name
  end

  test "new_booking includes booking details in body" do
    email = WellhubBookingMailer.new_booking(@booking)
    body = email.html_part.body.to_s

    assert_includes body, @booking.booking_number
    assert_includes body, @booking.gympass_id
    assert_includes body, @studio_class.name
  end

  test "new_booking skips when studio email is blank" do
    StudioSetting.set("studio_email", "")

    email = WellhubBookingMailer.new_booking(@booking)

    assert_emails 0 do
      email.deliver_now
    end
  end
end
