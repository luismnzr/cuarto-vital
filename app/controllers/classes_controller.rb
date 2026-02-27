class ClassesController < ApplicationController
  skip_after_action :verify_authorized, only: :index
  skip_after_action :verify_policy_scoped

  def index
    @week_start = if params[:week_start].present?
      Date.parse(params[:week_start]).beginning_of_week(:monday)
    else
      Date.current.beginning_of_week(:monday)
    end
    @week_end = @week_start + 6.days

    @studio_classes = StudioClass.scheduled
      .includes(class_template: :category, teacher: [])
      .for_date_range(@week_start, @week_end)
      .order(:date, :start_time)

    if params[:category].present?
      @studio_classes = @studio_classes.by_category(params[:category])
    end

    if params[:teacher].present?
      @studio_classes = @studio_classes.by_teacher(params[:teacher])
    end

    if params[:level].present?
      @studio_classes = @studio_classes.joins(:class_template).where(class_templates: { level: params[:level] })
    end

    @categories = Category.ordered
    @teachers = User.teachers.active.order(:first_name)
  end

  def show
    @studio_class = StudioClass.includes(:class_template, :teacher, :reservations, :waitlist_entries).find(params[:id])
    authorize @studio_class
  end
end
