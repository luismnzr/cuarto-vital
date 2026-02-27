class Package < ApplicationRecord
  has_many :user_packages, dependent: :restrict_with_error

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :credit_count, presence: true, numericality: { greater_than: 0 }
  validates :expiration_days, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(sort_order: :asc, price: :asc) }
end
