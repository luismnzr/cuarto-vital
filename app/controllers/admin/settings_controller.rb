module Admin
  class SettingsController < BaseController
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def show
    end

    def update
      params[:settings]&.each do |key, value|
        StudioSetting.set(key, value)
      end

      # Update Wellhub category mappings
      params[:wellhub_categories]&.each do |category_id, wellhub_id|
        Category.find_by(id: category_id)&.update(wellhub_category_id: wellhub_id.presence)
      end

      redirect_to admin_settings_path, notice: "Settings updated successfully."
    end

    def sync_wellhub
      unless StudioSetting.wellhub_enabled?
        redirect_to admin_settings_path, alert: "Wellhub integration is not enabled."
        return
      end

      WellhubScheduleSyncJob.perform_later
      redirect_to admin_settings_path, notice: "Wellhub sync started. Classes and slots will be synced shortly."
    end
  end
end
