module Teacher
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_teacher!
    layout "teacher"

    private

    def require_teacher!
      unless current_user&.teacher? || current_user&.admin?
        flash[:alert] = "You are not authorized to access the teacher area."
        redirect_to root_path
      end
    end
  end
end
