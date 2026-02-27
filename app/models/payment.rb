class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :payable, polymorphic: true, optional: true

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending succeeded failed refunded] }
  validates :payment_method, presence: true, inclusion: { in: %w[stripe cash card_in_person] }

  scope :succeeded, -> { where(status: "succeeded") }
  scope :recent, -> { order(created_at: :desc) }
end
