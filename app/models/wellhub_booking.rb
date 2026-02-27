class WellhubBooking < ApplicationRecord
  belongs_to :studio_class

  validates :booking_number, presence: true, uniqueness: true
  validates :gympass_id, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending accepted rejected cancelled checked_in] }
  validates :booked_at, presence: true

  scope :active, -> { where(status: %w[pending accepted]) }
  scope :accepted, -> { where(status: "accepted") }

  WELLHUB_STATUS_ACCEPTED = 2
  WELLHUB_STATUS_REJECTED = 3
  WELLHUB_STATUS_CANCELLED_BY_GYM = 5

  def accept!
    update!(status: "accepted", responded_at: Time.current)
  end

  def reject!
    update!(status: "rejected", responded_at: Time.current)
  end

  def cancel!
    update!(status: "cancelled", cancelled_at: Time.current)
  end

  def check_in!
    update!(status: "checked_in", checked_in_at: Time.current)
  end
end
