FactoryBot.define do
  factory :subscription_plan do
    name { "Monthly Unlimited" }
    price { 1800.00 }
    interval { "monthly" }
    description { "Unlimited monthly access" }
    active { true }
  end
end
