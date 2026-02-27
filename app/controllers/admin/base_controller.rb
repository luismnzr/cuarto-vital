module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    layout "admin"

    private

    # Turbo Drive requires 303 See Other for redirects after non-GET form
    # submissions so the browser follows the redirect with a GET request.
    def redirect_to(url = {}, options = {})
      if request.method != "GET" && !options.key?(:status)
        options[:status] = :see_other
      end
      super(url, options)
    end

    def require_admin!
      unless current_user&.admin?
        flash[:alert] = "You are not authorized to access the admin area."
        redirect_to root_path
      end
    end
  end
end
