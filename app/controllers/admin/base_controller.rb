module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    layout "admin"

    private

    # Turbo Drive requires 303 (See Other) for redirects after non-GET form
    # submissions, otherwise the browser may not follow the redirect properly.
    def redirect_to(url_or_options = {}, response_options = {})
      if request.method != "GET" && !response_options.key?(:status)
        response_options[:status] = :see_other
      end
      super
    end

    def require_admin!
      unless current_user&.admin?
        flash[:alert] = "You are not authorized to access the admin area."
        redirect_to root_path
      end
    end
  end
end
