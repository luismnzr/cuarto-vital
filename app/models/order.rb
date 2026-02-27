class Order < ApplicationRecord
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy
  accepts_nested_attributes_for :order_items, reject_if: :all_blank

  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed cancelled] }
  validates :payment_method, presence: true, inclusion: { in: %w[cash card stripe] }

  scope :completed, -> { where(status: "completed") }
  scope :recent, -> { order(created_at: :desc) }

  def calculate_total
    self.total = order_items.sum { |item| item.quantity * item.unit_price }
  end
end
