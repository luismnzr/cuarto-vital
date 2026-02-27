class Page < ApplicationRecord
  has_rich_text :body

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(sort_order: :asc) }

  private

  def generate_slug
    self.slug = title.parameterize
  end
end
