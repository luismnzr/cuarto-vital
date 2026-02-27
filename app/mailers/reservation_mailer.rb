class ReservationMailer < ApplicationMailer
  def confirmed(reservation)
    @reservation = reservation
    @user = reservation.user
    @studio_class = reservation.studio_class

    mail(to: @user.email, subject: "Reservation Confirmed — #{@studio_class.name}")
  end

  def cancelled(reservation)
    @reservation = reservation
    @user = reservation.user
    @studio_class = reservation.studio_class
    @credit_restored = reservation.class_credit.present? &&
      (!reservation.late_cancel || !StudioSetting.late_cancel_forfeit_credit?)

    mail(to: @user.email, subject: "Reservation Cancelled — #{@studio_class.name}")
  end

  def class_cancelled(reservation)
    @reservation = reservation
    @user = reservation.user
    @studio_class = reservation.studio_class

    mail(to: @user.email, subject: "Class Cancelled — #{@studio_class.name}")
  end

  def no_show(reservation)
    @reservation = reservation
    @user = reservation.user
    @studio_class = reservation.studio_class

    mail(to: @user.email, subject: "No-Show Recorded — #{@studio_class.name}")
  end
end
