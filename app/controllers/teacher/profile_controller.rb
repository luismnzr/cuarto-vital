module Teacher
  class ProfileController < BaseController
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def show
    end

    def edit
    end

    def update
      if current_user.update(profile_params)
        redirect_to teacher_profile_path, notice: "Profile updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:user).permit(:first_name, :last_name, :phone, :bio, :styles_taught, :photo)
    end
  end
end
