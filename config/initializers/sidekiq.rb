redis_config = {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
}

Sidekiq.configure_server do |config|
  config.redis = redis_config

  config.on(:startup) do
    Sidekiq::Cron::Job.create(
      name: "Generate scheduled classes - daily at 2am",
      cron: "0 2 * * *",
      class: "GenerateScheduledClassesJob"
    )

    Sidekiq::Cron::Job.create(
      name: "Reservation reminders - hourly",
      cron: "0 * * * *",
      class: "ReservationReminderJob"
    )

    Sidekiq::Cron::Job.create(
      name: "Package expiration warnings - daily at 9am",
      cron: "0 9 * * *",
      class: "PackageExpirationWarningJob"
    )

    Sidekiq::Cron::Job.create(
      name: "Package expiration - daily at midnight",
      cron: "0 0 * * *",
      class: "PackageExpirationJob"
    )

    Sidekiq::Cron::Job.create(
      name: "Wellhub schedule sync - every 30 minutes",
      cron: "*/30 * * * *",
      class: "WellhubScheduleSyncJob"
    )
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
