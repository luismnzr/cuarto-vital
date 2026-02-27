class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Method
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :verify_authorized, unless: -> { devise_controller? || action_name == "index" }
  after_action :verify_policy_scoped, if: -> { action_name == "index" && !devise_controller? }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone])
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

  def after_sign_in_path_for(resource)
    case resource.role
    when "admin"
      admin_dashboard_path
    when "teacher"
      teacher_dashboard_path
    else
      root_path
    end
  end
end
