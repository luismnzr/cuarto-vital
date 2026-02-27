module Admin
  class PackagesController < BaseController
    def index
      @packages = policy_scope(Package).ordered
    end

    def new
      @package = Package.new
      authorize @package
    end

    def create
      @package = Package.new(package_params)
      authorize @package
      if @package.save
        redirect_to admin_packages_path, notice: "Package created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @package = Package.find(params[:id])
      authorize @package
    end

    def update
      @package = Package.find(params[:id])
      authorize @package
      if @package.update(package_params)
        redirect_to admin_packages_path, notice: "Package updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @package = Package.find(params[:id])
      authorize @package
      if @package.user_packages.exists?
        @package.update!(active: false)
        redirect_to admin_packages_path, notice: "Package deactivated (has existing purchases)."
      else
        @package.destroy
        redirect_to admin_packages_path, notice: "Package deleted."
      end
    end

    private

    def package_params
      params.require(:package).permit(:name, :price, :credit_count, :expiration_days, :description, :active, :sort_order)
    end
  end
end
