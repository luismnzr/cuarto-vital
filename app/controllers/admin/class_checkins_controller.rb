module Admin
  class ClassCheckinsController < BaseController
    def create
      @studio_class = StudioClass.find(params[:class_id])
      authorize @studio_class, :update?

      user = User.find(params[:user_id])

      if params[:walk_in] == "1"
        package = Package.find(params[:package_id])
        result = WalkinCheckinService.walkin_purchase_and_checkin(
          user: user,
          studio_class: @studio_class,
          package: package,
          payment_method: params[:payment_method]
        )
      else
        result = WalkinCheckinService.checkin(user: user, studio_class: @studio_class)
      end

      if result.success?
        flash[:notice] = "#{user.full_name} checked in successfully."
      else
        flash[:alert] = result.error
      end

      redirect_to admin_class_path(@studio_class), status: :see_other
    end
  end
end
