class ExternalCheckin < ApplicationRecord
  belongs_to :studio_class

  validates :user_identifier, presence: true
  validates :platform, presence: true, inclusion: { in: %w[wellhub fitpass] }
  validates :checked_in_at, presence: true

  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :validated, -> { where(validated: true) }
end
