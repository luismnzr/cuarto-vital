namespace :classes do
  desc "Generate scheduled classes 14 days in advance from active templates"
  task generate: :environment do
    GenerateScheduledClassesJob.perform_now
  end
end
