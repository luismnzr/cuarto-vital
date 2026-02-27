FactoryBot.define do
  factory :package do
    name { "#{rand(5..20)} Class Pack" }
    price { 1000.00 }
    credit_count { 10 }
    expiration_days { 30 }
    description { "Test package" }
    active { true }
  end
end
