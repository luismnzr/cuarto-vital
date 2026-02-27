class SubscriptionPlan < ApplicationRecord
  has_many :user_subscriptions, dependent: :restrict_with_error

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :interval, presence: true, inclusion: { in: %w[monthly annual] }

  scope :active, -> { where(active: true) }
end
