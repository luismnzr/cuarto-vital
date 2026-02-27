FactoryBot.define do
  factory :user_package do
    association :user
    association :package
    purchased_at { Time.current }
    expires_at { 30.days.from_now }
    credits_remaining { 10 }
    status { "active" }
  end
end
