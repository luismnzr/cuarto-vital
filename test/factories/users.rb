FactoryBot.define do
  factory :user do
    first_name { "Test" }
    last_name { "User" }
    email { Faker::Internet.unique.email }
    password { "password" }
    password_confirmation { "password" }
    role { :student }
    active { true }

    trait :admin do
      role { :admin }
    end

    trait :teacher do
      role { :teacher }
    end

    trait :student do
      role { :student }
    end

    trait :inactive do
      active { false }
    end
  end
end
