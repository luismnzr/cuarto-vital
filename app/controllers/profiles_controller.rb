class ProfilesController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def show
    @user = current_user
  end

  def classes
    @upcoming_reservations = current_user.reservations.confirmed
      .joins(:studio_class)
      .where("studio_classes.date >= ?", Date.current)
      .includes(studio_class: [:class_template, :teacher])
      .order("studio_classes.date ASC, studio_classes.start_time ASC")

    @past_reservations = current_user.reservations
      .where(status: ["completed", "no_show", "cancelled"])
      .joins(:studio_class)
      .includes(studio_class: [:class_template, :teacher])
      .order("studio_classes.date DESC")
      .limit(20)
  end

  def package
    @user_package = current_user.active_package
    @package_history = current_user.user_packages.includes(:package).order(purchased_at: :desc)
  end

  def subscription
    @user_subscription = current_user.user_subscription
  end

  def waitlists
    @waitlist_entries = current_user.waitlist_entries.pending
      .includes(studio_class: [:class_template, :teacher])
      .order("studio_classes.date ASC")
  end

  def billing
    @payments = current_user.payments.recent.limit(20)
  end
end
