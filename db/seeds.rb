# frozen_string_literal: true

puts "Seeding Eclipse database..."

# Studio Settings
StudioSetting::DEFAULTS.each do |key, value|
  StudioSetting.find_or_create_by!(key: key) do |setting|
    setting.value = value
  end
end
StudioSetting.set("studio_name", "Eclipse Studio")
StudioSetting.set("studio_email", "hello@eclipse.dev")
StudioSetting.set("studio_phone", "+52 55 1234 5678")
StudioSetting.set("studio_address", "Av. Reforma 222, CDMX")
puts "  ✓ Studio settings"

# Users
admin = User.find_or_create_by!(email: "admin@eclipse.dev") do |u|
  u.first_name = "Admin"
  u.last_name = "User"
  u.password = "password"
  u.password_confirmation = "password"
  u.role = :admin
end

teacher = User.find_or_create_by!(email: "teacher@eclipse.dev") do |u|
  u.first_name = "María"
  u.last_name = "García"
  u.password = "password"
  u.password_confirmation = "password"
  u.role = :teacher
end

teacher2 = User.find_or_create_by!(email: "teacher2@eclipse.dev") do |u|
  u.first_name = "Carlos"
  u.last_name = "López"
  u.password = "password"
  u.password_confirmation = "password"
  u.role = :teacher
end

student = User.find_or_create_by!(email: "student@eclipse.dev") do |u|
  u.first_name = "Ana"
  u.last_name = "Martínez"
  u.password = "password"
  u.password_confirmation = "password"
  u.role = :student
end

student2 = User.find_or_create_by!(email: "student2@eclipse.dev") do |u|
  u.first_name = "Luis"
  u.last_name = "Hernández"
  u.password = "password"
  u.password_confirmation = "password"
  u.role = :student
end
puts "  ✓ Users"

# Categories
yoga = Category.find_or_create_by!(name: "Yoga") do |c|
  c.slug = "yoga"
  c.description = "Find balance and flexibility through yoga practice"
  c.sort_order = 1
end

pilates = Category.find_or_create_by!(name: "Pilates") do |c|
  c.slug = "pilates"
  c.description = "Strengthen your core with Pilates exercises"
  c.sort_order = 2
end

meditation = Category.find_or_create_by!(name: "Meditation") do |c|
  c.slug = "meditation"
  c.description = "Calm your mind with guided meditation"
  c.sort_order = 3
end
puts "  ✓ Categories"

# Class Templates
vinyasa = ClassTemplate.find_or_create_by!(name: "Vinyasa Flow") do |t|
  t.category = yoga
  t.style = "Vinyasa"
  t.level = "all_levels"
  t.description = "A dynamic flow class linking breath with movement. Suitable for all levels."
  t.default_duration = 60
  t.default_capacity = 20
end

hatha = ClassTemplate.find_or_create_by!(name: "Hatha Yoga") do |t|
  t.category = yoga
  t.style = "Hatha"
  t.level = "beginner"
  t.description = "A gentle introduction to yoga with basic poses and breathing techniques."
  t.default_duration = 60
  t.default_capacity = 25
end

power_yoga = ClassTemplate.find_or_create_by!(name: "Power Yoga") do |t|
  t.category = yoga
  t.style = "Power"
  t.level = "advanced"
  t.description = "An intense, fitness-based approach to vinyasa-style yoga."
  t.default_duration = 75
  t.default_capacity = 15
end

mat_pilates = ClassTemplate.find_or_create_by!(name: "Mat Pilates") do |t|
  t.category = pilates
  t.style = "Mat"
  t.level = "all_levels"
  t.description = "Core-strengthening exercises performed on a mat."
  t.default_duration = 50
  t.default_capacity = 18
end

reformer = ClassTemplate.find_or_create_by!(name: "Reformer Pilates") do |t|
  t.category = pilates
  t.style = "Reformer"
  t.level = "intermediate"
  t.description = "Pilates exercises using the reformer machine for resistance training."
  t.default_duration = 50
  t.default_capacity = 10
end

guided_meditation = ClassTemplate.find_or_create_by!(name: "Guided Meditation") do |t|
  t.category = meditation
  t.style = "Guided"
  t.level = "beginner"
  t.description = "A relaxing guided meditation session to reduce stress and improve focus."
  t.default_duration = 30
  t.default_capacity = 30
end
puts "  ✓ Class templates"

# Packages
Package.find_or_create_by!(name: "5 Class Pack") do |p|
  p.price = 750.00
  p.credit_count = 5
  p.expiration_days = 30
  p.description = "5 classes to use within 30 days"
  p.sort_order = 1
end

Package.find_or_create_by!(name: "10 Class Pack") do |p|
  p.price = 1350.00
  p.credit_count = 10
  p.expiration_days = 60
  p.description = "10 classes to use within 60 days"
  p.sort_order = 2
end

Package.find_or_create_by!(name: "20 Class Pack") do |p|
  p.price = 2400.00
  p.credit_count = 20
  p.expiration_days = 90
  p.description = "20 classes to use within 90 days. Best value!"
  p.sort_order = 3
end
puts "  ✓ Packages"

# Subscription Plans
SubscriptionPlan.find_or_create_by!(name: "Monthly Unlimited") do |sp|
  sp.price = 1800.00
  sp.interval = "monthly"
  sp.description = "Unlimited classes every month"
end

SubscriptionPlan.find_or_create_by!(name: "Annual Unlimited") do |sp|
  sp.price = 16200.00
  sp.interval = "annual"
  sp.description = "Unlimited classes for a full year. Save 25%!"
end
puts "  ✓ Subscription plans"

# Scheduled Classes (2 weeks)
templates = [vinyasa, hatha, power_yoga, mat_pilates, reformer, guided_meditation]
teachers = [teacher, teacher2]
start_date = Date.current.beginning_of_week
end_date = start_date + 13.days

schedule = {
  0 => [ # Monday
    { template: vinyasa, time: "07:00", teacher: teacher },
    { template: mat_pilates, time: "09:00", teacher: teacher2 },
    { template: power_yoga, time: "17:00", teacher: teacher },
    { template: guided_meditation, time: "19:00", teacher: teacher2 }
  ],
  1 => [ # Tuesday
    { template: hatha, time: "07:00", teacher: teacher2 },
    { template: reformer, time: "09:00", teacher: teacher },
    { template: vinyasa, time: "17:00", teacher: teacher2 },
    { template: mat_pilates, time: "19:00", teacher: teacher }
  ],
  2 => [ # Wednesday
    { template: vinyasa, time: "07:00", teacher: teacher },
    { template: mat_pilates, time: "09:00", teacher: teacher2 },
    { template: power_yoga, time: "17:00", teacher: teacher },
    { template: guided_meditation, time: "19:00", teacher: teacher2 }
  ],
  3 => [ # Thursday
    { template: hatha, time: "07:00", teacher: teacher2 },
    { template: reformer, time: "09:00", teacher: teacher },
    { template: vinyasa, time: "17:00", teacher: teacher2 },
    { template: mat_pilates, time: "19:00", teacher: teacher }
  ],
  4 => [ # Friday
    { template: vinyasa, time: "07:00", teacher: teacher },
    { template: mat_pilates, time: "09:00", teacher: teacher2 },
    { template: power_yoga, time: "17:00", teacher: teacher }
  ],
  5 => [ # Saturday
    { template: hatha, time: "09:00", teacher: teacher },
    { template: vinyasa, time: "10:30", teacher: teacher2 },
    { template: guided_meditation, time: "12:00", teacher: teacher }
  ],
  6 => [ # Sunday
    { template: hatha, time: "09:00", teacher: teacher2 },
    { template: guided_meditation, time: "10:30", teacher: teacher }
  ]
}

class_count = 0
(start_date..end_date).each do |date|
  day_schedule = schedule[date.wday == 0 ? 6 : date.wday - 1]
  next unless day_schedule

  day_schedule.each do |slot|
    template = slot[:template]
    start_time = Time.zone.parse("#{date} #{slot[:time]}")
    end_time = start_time + template.default_duration.minutes

    StudioClass.find_or_create_by!(
      class_template: template,
      date: date,
      start_time: start_time
    ) do |sc|
      sc.teacher = slot[:teacher]
      sc.end_time = end_time
      sc.duration = template.default_duration
      sc.capacity = template.default_capacity
      sc.spots_remaining = template.default_capacity
      sc.status = "scheduled"
    end
    class_count += 1
  end
end
puts "  ✓ #{class_count} scheduled classes (2 weeks)"

puts "\nSeeding complete!"
puts "  Admin:   admin@eclipse.dev / password"
puts "  Teacher: teacher@eclipse.dev / password"
puts "  Student: student@eclipse.dev / password"
