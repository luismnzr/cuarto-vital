class StudioSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  DEFAULTS = {
    "studio_name" => "Studio",
    "studio_email" => "",
    "studio_phone" => "",
    "studio_address" => "",
    "studio_timezone" => "America/Mexico_City",
    "cancellation_window_hours" => "12",
    "late_cancel_forfeit_credit" => "true",
    "waitlist_enabled" => "true",
    "max_waitlist_size" => "5",
    "booking_window_days" => "14",
    "currency" => "mxn",
    "shop_enabled" => "false",
    "wellhub_enabled" => "false",
    "wellhub_gym_id" => "",
    "wellhub_product_id" => ""
  }.freeze

  def self.get(key)
    find_by(key: key)&.value || DEFAULTS[key.to_s]
  end

  ALLOWED_KEYS = DEFAULTS.keys.freeze

  def self.set(key, value)
    unless ALLOWED_KEYS.include?(key.to_s)
      Rails.logger.warn "Rejected unknown studio setting key: #{key}"
      return
    end

    setting = find_or_initialize_by(key: key)
    setting.update!(value: value.to_s)
  end

  def self.studio_timezone
    get("studio_timezone") || "America/Mexico_City"
  end

  def self.cancellation_window_hours
    get("cancellation_window_hours").to_i
  end

  def self.waitlist_enabled?
    get("waitlist_enabled") == "true"
  end

  def self.max_waitlist_size
    get("max_waitlist_size").to_i
  end

  def self.booking_window_days
    get("booking_window_days").to_i
  end

  def self.currency
    get("currency") || "mxn"
  end

  def self.shop_enabled?
    get("shop_enabled") == "true"
  end

  def self.late_cancel_forfeit_credit?
    get("late_cancel_forfeit_credit") == "true"
  end

  def self.wellhub_enabled?
    get("wellhub_enabled") == "true"
  end

  def self.wellhub_gym_id
    get("wellhub_gym_id").presence || ENV["WELLHUB_GYM_ID"]
  end
end
