class ReservationReminderJob < ApplicationJob
  queue_as :mailers

  def perform
    timezone = StudioSetting.studio_timezone
    Time.use_zone(timezone) do
      reminder_window_start = 2.hours.from_now.beginning_of_minute
      reminder_window_end = reminder_window_start + 59.minutes

      studio_classes = StudioClass.scheduled
        .where(date: Date.current)
        .includes(reservations: :user)

      studio_classes.each do |studio_class|
        starts_at = studio_class.starts_at
        next unless starts_at.present?
        next unless starts_at >= reminder_window_start && starts_at <= reminder_window_end

        studio_class.reservations.confirmed.includes(:user).find_each do |reservation|
          ReminderMailer.class_reminder(reservation).deliver_later
        end
      end
    end
  end
end
