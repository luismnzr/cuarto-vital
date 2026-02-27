class Category < ApplicationRecord
  has_many :class_templates, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :ordered, -> { order(sort_order: :asc, name: :asc) }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
