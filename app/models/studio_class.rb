class StudioClass < ApplicationRecord
  belongs_to :class_template
  belongs_to :teacher, class_name: "User"
  has_many :reservations, dependent: :destroy
  has_many :waitlist_entries, dependent: :destroy
  has_many :external_checkins, dependent: :destroy
  has_many :wellhub_bookings, dependent: :destroy

  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0 }
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :spots_remaining, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[scheduled cancelled completed] }

  after_update :cancel_wellhub_bookings_on_cancellation
  after_commit :enqueue_wellhub_capacity_sync, if: :wellhub_capacity_changed?

  scope :scheduled, -> { where(status: "scheduled") }
  scope :upcoming, -> { where("date > ? OR (date = ? AND start_time > ?)", Date.current, Date.current, Time.current.strftime("%H:%M:%S")) }
  scope :today, -> { where(date: Date.current) }
  scope :this_week, -> { where(date: Date.current..Date.current.end_of_week) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :by_teacher, ->(teacher_id) { where(teacher_id: teacher_id) }
  scope :by_category, ->(category_id) { joins(:class_template).where(class_templates: { category_id: category_id }) }

  delegate :name, :description, :level, :style, :category, to: :class_template

  def full?
    spots_remaining <= 0
  end

  def starts_at
    return nil unless date && start_time
    Time.zone.parse("#{date} #{start_time.strftime('%H:%M')}")
  end

  def confirmed_reservations
    reservations.where(status: "confirmed")
  end

  def confirmed_count
    confirmed_reservations.count
  end

  def waitlist_count
    waitlist_entries.where(status: "pending").count
  end

  private

  def wellhub_capacity_changed?
    wellhub_slot_id.present? && (saved_change_to_spots_remaining? || saved_change_to_capacity?)
  end

  def enqueue_wellhub_capacity_sync
    WellhubCapacitySyncJob.perform_later(id)
  end

  def cancel_wellhub_bookings_on_cancellation
    return unless saved_change_to_status? && status == "cancelled"
    return unless wellhub_slot_id.present?

    gym_id = StudioSetting.wellhub_gym_id
    return unless gym_id

    wellhub_bookings.where(status: %w[pending accepted]).find_each do |booking|
      booking.cancel!
      WellhubClient.update_booking(
        gym_id: gym_id,
        booking_number: booking.booking_number,
        status: WellhubBooking::WELLHUB_STATUS_CANCELLED_BY_GYM
      )
    rescue WellhubClient::Error => e
      Rails.logger.error "Failed to cancel Wellhub booking #{booking.booking_number}: #{e.message}"
    end
  end
end
