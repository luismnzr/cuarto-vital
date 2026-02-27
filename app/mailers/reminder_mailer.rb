class ReminderMailer < ApplicationMailer
  def class_reminder(reservation)
    @reservation = reservation
    @user = reservation.user
    @studio_class = reservation.studio_class

    mail(to: @user.email, subject: "Class Reminder — #{@studio_class.name} Today")
  end
end
