class UserPackage < ApplicationRecord
  belongs_to :user
  belongs_to :package
  has_many :class_credits, dependent: :destroy

  validates :purchased_at, presence: true
  validates :expires_at, presence: true
  validates :credits_remaining, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[active expired depleted] }

  scope :active, -> { where(status: "active").where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def depleted?
    credits_remaining <= 0
  end

  def use_credit!
    raise "No credits remaining" if depleted?
    raise "Package expired" if expired?

    credit = class_credits.create!(used_at: Time.current)
    decrement!(:credits_remaining)
    update!(status: "depleted") if credits_remaining <= 0
    credit
  end

  def restore_credit!(class_credit)
    class_credit.update!(used_at: nil)
    increment!(:credits_remaining)
    update!(status: "active") if status == "depleted"
  end
end
