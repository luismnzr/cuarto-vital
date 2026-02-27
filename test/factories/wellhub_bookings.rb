FactoryBot.define do
  factory :wellhub_booking do
    association :studio_class
    sequence(:booking_number) { |n| "WH-BOOK-#{n}" }
    sequence(:gympass_id) { |n| "gpw_#{n}" }
    status { "accepted" }
    booked_at { Time.current }
    responded_at { Time.current }

    trait :pending do
      status { "pending" }
      responded_at { nil }
    end

    trait :rejected do
      status { "rejected" }
    end

    trait :cancelled do
      status { "cancelled" }
      cancelled_at { Time.current }
    end

    trait :checked_in do
      status { "checked_in" }
      checked_in_at { Time.current }
    end
  end
end
