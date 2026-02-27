FactoryBot.define do
  factory :class_credit do
    association :user_package
    used_at { nil }

    trait :used do
      used_at { Time.current }
    end
  end
end
