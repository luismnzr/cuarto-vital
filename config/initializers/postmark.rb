Rails.application.config.after_initialize do
  if Rails.env.production?
    ActionMailer::Base.default(message_stream: "outbound")
  end
end
