class ClassCredit < ApplicationRecord
  belongs_to :user_package
  has_one :reservation, dependent: :nullify

  scope :used, -> { where.not(used_at: nil) }
  scope :unused, -> { where(used_at: nil) }
end
