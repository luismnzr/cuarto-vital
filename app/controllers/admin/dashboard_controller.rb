module Admin
  class DashboardController < BaseController
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def show
      @total_students = User.students.count
      @total_teachers = User.teachers.count
      @classes_today = StudioClass.today.count
      @reservations_today = Reservation.confirmed.joins(:studio_class).merge(StudioClass.today).count
      @recent_reservations = Reservation.includes(:user, studio_class: :class_template).order(created_at: :desc).limit(10)

      # Revenue stats
      @revenue_this_month = UserPackage.where("user_packages.created_at >= ?", Date.current.beginning_of_month)
                                       .joins(:package).sum("packages.price")
      @active_subscriptions = UserSubscription.where(status: "active").count

      # Weekly class data for chart (last 7 days)
      @weekly_classes = (6.downto(0)).map do |i|
        day = Date.current - i.days
        {
          date: day,
          label: day.strftime("%a"),
          classes: StudioClass.where(date: day).count,
          bookings: Reservation.confirmed.joins(:studio_class).where(studio_classes: { date: day }).count
        }
      end
    end
  end
end
