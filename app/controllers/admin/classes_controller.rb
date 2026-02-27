module Admin
  class ClassesController < BaseController
    def index
      scope = policy_scope(StudioClass)
        .includes(class_template: :category, teacher: [])

      if params[:tab] == "past"
        @studio_classes = scope.where("date < ?", Date.current).order(date: :desc, start_time: :desc)
      else
        @studio_classes = scope.where("date >= ?", Date.current).order(date: :asc, start_time: :asc)
      end

      @pagy, @studio_classes = pagy(@studio_classes)
    end

    def show
      @studio_class = StudioClass.find(params[:id])
      authorize @studio_class
      @reservations = @studio_class.reservations.includes(:user).where.not(status: "cancelled")
      @waitlist_entries = @studio_class.waitlist_entries.pending.ordered.includes(:user)
      @students = User.students.active.order(:first_name, :last_name)
      @packages = Package.active.order(:sort_order, :price)
    end

    def new
      @studio_class = StudioClass.new
      authorize @studio_class
      @class_templates = ClassTemplate.active
      @teachers = User.teachers.active
    end

    def create
      @studio_class = StudioClass.new(studio_class_params)
      authorize @studio_class

      template = @studio_class.class_template
      if template
        @studio_class.duration ||= template.default_duration
        @studio_class.capacity ||= template.default_capacity
        @studio_class.spots_remaining = @studio_class.capacity
        @studio_class.end_time ||= @studio_class.start_time + @studio_class.duration.minutes if @studio_class.start_time
      end

      if @studio_class.save
        redirect_to admin_classes_path, notice: "Class created successfully."
      else
        @class_templates = ClassTemplate.active
        @teachers = User.teachers.active
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @studio_class = StudioClass.find(params[:id])
      authorize @studio_class
      @class_templates = ClassTemplate.active
      @teachers = User.teachers.active
    end

    def update
      @studio_class = StudioClass.find(params[:id])
      authorize @studio_class
      if @studio_class.update(studio_class_params)
        redirect_to admin_classes_path, notice: "Class updated successfully."
      else
        @class_templates = ClassTemplate.active
        @teachers = User.teachers.active
        render :edit, status: :unprocessable_entity
      end
    end

    def remove_student
      @studio_class = StudioClass.find(params[:class_id])
      authorize @studio_class, :update?
      reservation = @studio_class.reservations.find(params[:reservation_id])
      return_credit = params[:return_credit] == "1"
      student_name = reservation.user.full_name

      ActiveRecord::Base.transaction do
        reservation.cancel!(late: false)

        if return_credit && reservation.class_credit.present?
          CreditDeductionService.restore(reservation)
        end

        @studio_class.increment!(:spots_remaining)

        if @studio_class.waitlist_count > 0
          WaitlistService.promote_next(studio_class: @studio_class)
        end
      end

      credit_msg = return_credit ? " Credit returned." : ""
      redirect_to admin_class_path(@studio_class), notice: "#{student_name} removed from class.#{credit_msg}"
    rescue => e
      redirect_to admin_class_path(@studio_class), alert: "Failed to remove student: #{e.message}"
    end

    def destroy
      @studio_class = StudioClass.find(params[:id])
      authorize @studio_class

      ActiveRecord::Base.transaction do
        @studio_class.update!(status: "cancelled")

        @studio_class.reservations.confirmed.includes(:user, :class_credit).find_each do |reservation|
          CreditDeductionService.restore(reservation) if reservation.class_credit.present?
          reservation.cancel!(late: false)
          ReservationMailer.class_cancelled(reservation).deliver_later
        end

        @studio_class.waitlist_entries.pending.includes(:user).find_each do |entry|
          entry.expire!
          WaitlistMailer.expired(entry).deliver_later
        end
      end

      redirect_to admin_classes_path, notice: "Class cancelled. All students have been notified."
    end

    private

    def studio_class_params
      params.require(:studio_class).permit(:class_template_id, :teacher_id, :date, :start_time, :end_time, :duration, :capacity, :spots_remaining, :status)
    end
  end
end
