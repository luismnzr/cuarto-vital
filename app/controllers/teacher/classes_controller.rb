module Teacher
  class ClassesController < BaseController
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def index
      @studio_classes = current_user.teaching_classes
        .scheduled
        .includes(:class_template, :reservations)
        .order(:date, :start_time)
    end

    def show
      @studio_class = current_user.teaching_classes.find(params[:id])
      @reservations = @studio_class.reservations.confirmed.includes(:user)
      @waitlist_entries = @studio_class.waitlist_entries.pending.ordered.includes(:user)
    end
  end
end
