class Product < ApplicationRecord
  has_many :order_items, dependent: :restrict_with_error
  has_one_attached :image

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where("stock_quantity > 0") }
end
