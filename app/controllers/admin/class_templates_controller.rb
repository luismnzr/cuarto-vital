module Admin
  class ClassTemplatesController < BaseController
    def index
      @class_templates = policy_scope(ClassTemplate).includes(:category, :teacher).order(:name)
    end

    def new
      @class_template = ClassTemplate.new
      authorize @class_template
      load_form_data
    end

    def create
      @class_template = ClassTemplate.new(class_template_params)
      authorize @class_template
      if @class_template.save
        redirect_to admin_class_templates_path, notice: "Class template created."
      else
        load_form_data
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @class_template = ClassTemplate.find(params[:id])
      authorize @class_template
      load_form_data
    end

    def update
      @class_template = ClassTemplate.find(params[:id])
      authorize @class_template
      if @class_template.update(class_template_params)
        redirect_to admin_class_templates_path, notice: "Class template updated."
      else
        load_form_data
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @class_template = ClassTemplate.find(params[:id])
      authorize @class_template
      @class_template.destroy
      redirect_to admin_class_templates_path, notice: "Class template deleted."
    end

    private

    def load_form_data
      @categories = Category.ordered
      @teachers = User.teachers.active
    end

    def class_template_params
      params.require(:class_template).permit(:name, :category_id, :style, :level, :description, :default_duration, :default_capacity, :active, :image, :day_of_week, :default_start_time, :teacher_id)
    end
  end
end
