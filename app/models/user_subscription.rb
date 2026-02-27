class UserSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :subscription_plan

  validates :status, presence: true, inclusion: { in: %w[active past_due cancelled inactive] }

  scope :active, -> { where(status: "active") }

  def active?
    status == "active" && (current_period_end.nil? || current_period_end > Time.current)
  end

  def cancel!
    update!(status: "cancelled")
  end
end
