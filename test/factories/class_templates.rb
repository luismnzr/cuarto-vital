FactoryBot.define do
  factory :class_template do
    association :category
    name { "#{Faker::Adjective.positive.capitalize} Flow" }
    style { "Vinyasa" }
    level { "all_levels" }
    description { Faker::Lorem.paragraph }
    default_duration { 60 }
    default_capacity { 20 }
    active { true }
  end
end
