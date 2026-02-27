class WaitlistEntry < ApplicationRecord
  belongs_to :user
  belongs_to :studio_class

  validates :position, presence: true, numericality: { greater_than: 0 }
  validates :joined_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending promoted expired cancelled] }
  validates :user_id, uniqueness: { scope: :studio_class_id, message: "is already on the waitlist for this class" }

  scope :pending, -> { where(status: "pending") }
  scope :ordered, -> { order(position: :asc) }

  def promote!
    update!(status: "promoted", promoted_at: Time.current)
  end

  def expire!
    update!(status: "expired")
  end

  def cancel!
    update!(status: "cancelled")
  end
end
