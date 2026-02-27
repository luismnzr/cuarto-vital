# frozen_string_literal: true

module Admin
  class ProductsController < BaseController
    def index
      @products = policy_scope(Product).order(active: :desc, name: :asc)
    end

    def new
      @product = Product.new(active: true, stock_quantity: 0)
      authorize @product
    end

    def create
      @product = Product.new(product_params)
      authorize @product
      if @product.save
        redirect_to admin_products_path, notice: "Product created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @product = Product.find(params[:id])
      authorize @product
    end

    def update
      @product = Product.find(params[:id])
      authorize @product
      if @product.update(product_params)
        redirect_to admin_products_path, notice: "Product updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product = Product.find(params[:id])
      authorize @product
      if @product.order_items.exists?
        @product.update!(active: false)
        redirect_to admin_products_path, notice: "Product deactivated (has existing orders)."
      else
        @product.destroy
        redirect_to admin_products_path, notice: "Product deleted."
      end
    end

    private

    def product_params
      params.require(:product).permit(:name, :description, :price, :stock_quantity, :active, :image)
    end
  end
end
