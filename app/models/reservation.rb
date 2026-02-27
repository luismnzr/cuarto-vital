class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :studio_class
  belongs_to :class_credit, optional: true

  validates :status, presence: true, inclusion: { in: %w[confirmed cancelled completed no_show] }
  validates :user_id, uniqueness: {
    scope: :studio_class_id,
    conditions: -> { where.not(status: "cancelled") },
    message: "already has a reservation for this class"
  }

  scope :confirmed, -> { where(status: "confirmed") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :completed, -> { where(status: "completed") }
  scope :no_show, -> { where(status: "no_show") }
  scope :upcoming, -> { joins(:studio_class).merge(StudioClass.upcoming).confirmed }
  scope :past, -> { joins(:studio_class).where("studio_classes.date < ?", Date.current) }

  def cancel!(late: false)
    update!(status: "cancelled", cancelled_at: Time.current, late_cancel: late)
  end

  def complete!
    update!(status: "completed")
  end

  def mark_no_show!
    update!(status: "no_show")
    ReservationMailer.no_show(self).deliver_later
  end
end
