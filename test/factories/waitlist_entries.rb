FactoryBot.define do
  factory :waitlist_entry do
    association :user
    association :studio_class
    position { 1 }
    joined_at { Time.current }
    status { "pending" }
  end
end
