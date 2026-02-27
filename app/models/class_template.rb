class ClassTemplate < ApplicationRecord
  belongs_to :category
  belongs_to :teacher, class_name: "User", optional: true
  has_many :studio_classes, dependent: :destroy
  has_one_attached :image

  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  validates :name, presence: true
  validates :level, presence: true, inclusion: { in: %w[beginner intermediate advanced all_levels] }
  validates :default_duration, presence: true, numericality: { greater_than: 0 }
  validates :default_capacity, presence: true, numericality: { greater_than: 0 }
  validates :day_of_week, inclusion: { in: 0..6 }, allow_nil: true
  validates :teacher, presence: true, if: -> { day_of_week.present? }
  validates :default_start_time, presence: true, if: -> { day_of_week.present? }

  scope :active, -> { where(active: true) }
  scope :scheduled, -> { where.not(day_of_week: nil) }

  def display_level
    level.titleize
  end

  def display_day
    day_of_week.present? ? DAY_NAMES[day_of_week] : nil
  end

  def scheduled?
    day_of_week.present?
  end
end
