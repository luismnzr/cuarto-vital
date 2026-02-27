class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { student: 0, teacher: 1, admin: 2 }

  has_many :reservations, dependent: :destroy
  has_many :waitlist_entries, dependent: :destroy
  has_many :user_packages, dependent: :destroy
  has_one :user_subscription, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :orders

  has_many :teaching_classes, class_name: "StudioClass", foreign_key: :teacher_id, dependent: :nullify, inverse_of: :teacher

  has_one_attached :photo

  validates :first_name, presence: true
  validates :last_name, presence: true

  after_create_commit :send_welcome_email, if: :student?

  scope :active, -> { where(active: true) }
  scope :students, -> { where(role: :student) }
  scope :teachers, -> { where(role: :teacher) }
  scope :admins, -> { where(role: :admin) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def styles_list
    styles_taught.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  def styles_list=(list)
    self.styles_taught = Array(list).reject(&:blank?).join(", ")
  end

  def active_package
    user_packages.where(status: "active").where("expires_at > ?", Time.current).order(expires_at: :asc).first
  end

  def active_subscription
    user_subscription&.active? ? user_subscription : nil
  end

  def has_available_credits?
    active_package&.credits_remaining&.positive? || false
  end

  def has_active_subscription?
    user_subscription&.status == "active"
  end

  def can_reserve?
    has_available_credits? || has_active_subscription?
  end

  private

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
