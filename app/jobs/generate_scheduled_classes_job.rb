class GenerateScheduledClassesJob < ApplicationJob
  queue_as :default

  def perform
    target_date = 14.days.from_now.to_date

    ClassTemplate.active.scheduled.find_each do |template|
      next unless target_date.wday == template.day_of_week

      # Skip if a class already exists for this template on the target date
      next if template.studio_classes.exists?(date: target_date)

      start_time = template.default_start_time
      duration = template.default_duration
      end_time = start_time + duration.minutes

      template.studio_classes.create!(
        teacher: template.teacher,
        date: target_date,
        start_time: start_time,
        end_time: end_time,
        duration: duration,
        capacity: template.default_capacity,
        spots_remaining: template.default_capacity,
        status: "scheduled"
      )
    end
  end
end
