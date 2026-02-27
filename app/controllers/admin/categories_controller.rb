module Admin
  class CategoriesController < BaseController
    def index
      @categories = policy_scope(Category).ordered
    end

    def new
      @category = Category.new
      authorize @category
    end

    def create
      @category = Category.new(category_params)
      authorize @category
      if @category.save
        redirect_to admin_categories_path, notice: "Category created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @category = Category.find(params[:id])
      authorize @category
    end

    def update
      @category = Category.find(params[:id])
      authorize @category
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Category updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @category = Category.find(params[:id])
      authorize @category
      @category.destroy
      redirect_to admin_categories_path, notice: "Category deleted."
    end

    private

    def category_params
      params.require(:category).permit(:name, :description, :sort_order)
    end
  end
end
