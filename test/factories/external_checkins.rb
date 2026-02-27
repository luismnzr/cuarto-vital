FactoryBot.define do
  factory :external_checkin do
    association :studio_class
    sequence(:user_identifier) { |n| "gpw_#{n}" }
    platform { "wellhub" }
    checked_in_at { Time.current }
    validated { false }

    trait :validated do
      validated { true }
    end

    trait :fitpass do
      platform { "fitpass" }
    end
  end
end
