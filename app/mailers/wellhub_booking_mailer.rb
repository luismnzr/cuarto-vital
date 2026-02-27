class WellhubBookingMailer < ApplicationMailer
  def new_booking(booking)
    @booking = booking
    @studio_class = booking.studio_class

    admin_email = StudioSetting.get("studio_email")
    return unless admin_email.present?

    mail(to: admin_email, subject: "New Wellhub Booking — #{@studio_class.name}")
  end
end
