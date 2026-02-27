FactoryBot.define do
  factory :reservation do
    association :user
    association :studio_class
    status { "confirmed" }

    trait :cancelled do
      status { "cancelled" }
      cancelled_at { Time.current }
    end

    trait :completed do
      status { "completed" }
    end

    trait :no_show do
      status { "no_show" }
    end
  end
end
