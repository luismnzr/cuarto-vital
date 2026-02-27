FactoryBot.define do
  factory :studio_class do
    association :class_template
    association :teacher, factory: [:user, :teacher]
    date { Date.current + 1.day }
    start_time { Time.zone.parse("09:00") }
    end_time { Time.zone.parse("10:00") }
    duration { 60 }
    capacity { 20 }
    spots_remaining { 20 }
    status { "scheduled" }

    trait :full do
      spots_remaining { 0 }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :today do
      date { Date.current }
      start_time { Time.zone.parse("#{Time.current.hour + 2}:00") }
      end_time { Time.zone.parse("#{Time.current.hour + 3}:00") }
    end
  end
end
