class ApplicationMailer < ActionMailer::Base
  default from: -> { "#{studio_name} <#{from_address}>" }
  layout "mailer"

  helper :mailer

  private

  def studio_name
    StudioSetting.get("studio_name")
  end

  def from_address
    ENV.fetch("MAILER_FROM_ADDRESS", "hello@eclipse.dev")
  end
end
