module Admin
  class UsersController < BaseController
    def index
      @users = policy_scope(User).order(created_at: :desc)
      @users = @users.where(role: params[:role]) if params[:role].present?
      @pagy, @users = pagy(@users)
    end

    def show
      @user = User.find(params[:id])
      authorize @user
      @packages = Package.active.order(:sort_order, :price) if @user.student?
      @payments = @user.payments.recent.limit(15)
    end

    def new
      @user = User.new
      authorize @user
    end

    def create
      @user = User.new(user_create_params)
      authorize @user
      if @user.save
        redirect_to admin_user_path(@user), notice: "#{@user.full_name} created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def sell_package
      @user = User.find(params[:id])
      authorize @user, :update?

      package = Package.find(params[:package_id])
      currency = StudioSetting.get("currency") || "mxn"

      ActiveRecord::Base.transaction do
        user_package = UserPackage.create!(
          user: @user,
          package: package,
          credits_remaining: package.credit_count,
          status: "active",
          purchased_at: Time.current,
          expires_at: Time.current + package.expiration_days.days
        )

        Payment.create!(
          user: @user,
          amount: package.price,
          currency: currency,
          status: "succeeded",
          payment_method: params[:payment_method],
          description: "#{package.name} — in-person purchase",
          payable: user_package
        )
      end

      redirect_to admin_user_path(@user), notice: "#{package.name} sold to #{@user.full_name} successfully."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_user_path(@user), alert: "Failed to sell package: #{e.message}"
    end

    def destroy
      @user = User.find(params[:id])
      authorize @user
      @user.destroy!
      redirect_to admin_users_path, notice: "#{@user.full_name} has been deleted."
    end

    def edit
      @user = User.find(params[:id])
      authorize @user
    end

    def update
      @user = User.find(params[:id])
      authorize @user
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :role, :active, :phone, :bio, :styles_taught, :photo)
    end

    def user_create_params
      params.require(:user).permit(:first_name, :last_name, :email, :role, :active, :phone, :password, :password_confirmation, :bio, :styles_taught, :photo)
    end
  end
end
