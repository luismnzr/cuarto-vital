FactoryBot.define do
  factory :user_subscription do
    association :user
    association :subscription_plan
    status { "active" }
    current_period_start { Time.current }
    current_period_end { 1.month.from_now }
  end
end
