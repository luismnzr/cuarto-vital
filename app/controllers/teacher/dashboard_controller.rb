module Teacher
  class DashboardController < BaseController
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def show
      teaching = current_user.teaching_classes

      # Stats
      month_classes = teaching.where(date: Date.current.beginning_of_month..Date.current.end_of_month)
      @classes_this_month = month_classes.count
      @total_students = Reservation.confirmed.where(studio_class_id: teaching.select(:id)).distinct.count(:user_id)
      @hours_taught = teaching.where(status: "completed").sum(:duration) / 60.0
      completed_classes = teaching.where(status: "completed")
      if completed_classes.any?
        total_capacity = completed_classes.sum(:capacity)
        total_attended = Reservation.where(studio_class_id: completed_classes.select(:id), status: "completed").count
        @attendance_rate = total_capacity > 0 ? (total_attended.to_f / total_capacity * 100).round : 0
      else
        @attendance_rate = 0
      end

      # Upcoming classes (next 7 days, excluding past today)
      @upcoming_classes = teaching.scheduled
        .where("date > ? OR (date = ? AND start_time > ?)", Date.current, Date.current, Time.current.strftime("%H:%M:%S"))
        .where(date: ..Date.current + 7.days)
        .includes(:class_template, reservations: :user)
        .order(:date, :start_time)
        .limit(6)

      # Weekly schedule (recurring templates for this teacher)
      @weekly_schedule = ClassTemplate.where(teacher_id: current_user.id)
        .where.not(day_of_week: nil)
        .active
        .order(:day_of_week, :default_start_time)
    end
  end
end
