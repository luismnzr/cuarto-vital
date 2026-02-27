class WellhubScheduleSyncJob < ApplicationJob
  queue_as :default

  LOCK_KEY = "wellhub_schedule_sync_lock"
  LOCK_TTL = 25.minutes.to_i

  def perform
    return unless ENV["WELLHUB_API_KEY"].present?
    return unless StudioSetting.wellhub_enabled?

    # Prevent overlapping runs using a Redis advisory lock
    acquired = Sidekiq.redis { |conn| conn.set(LOCK_KEY, Process.pid.to_s, nx: true, ex: LOCK_TTL) }
    unless acquired
      Rails.logger.info "WellhubScheduleSyncJob skipped — another instance is running"
      return
    end

    begin
      WellhubScheduleSyncService.sync_all
    ensure
      Sidekiq.redis { |conn| conn.del(LOCK_KEY) }
    end
  end
end
