class WaitlistService
  Result = Struct.new(:success?, :entry, :error, keyword_init: true)

  def self.join(user:, studio_class:)
    return Result.new(success?: false, error: "Waitlist is not enabled") unless StudioSetting.waitlist_enabled?
    return Result.new(success?: false, error: "This class is not full — you can reserve directly") unless studio_class.full?
    return Result.new(success?: false, error: "You already have a reservation for this class") if user.reservations.confirmed.where(studio_class: studio_class).exists?
    return Result.new(success?: false, error: "You are already on the waitlist for this class") if user.waitlist_entries.pending.where(studio_class: studio_class).exists?

    max_size = StudioSetting.max_waitlist_size
    current_count = studio_class.waitlist_count
    return Result.new(success?: false, error: "The waitlist is full") if current_count >= max_size

    next_position = (studio_class.waitlist_entries.maximum(:position) || 0) + 1

    entry = user.waitlist_entries.create!(
      studio_class: studio_class,
      position: next_position,
      joined_at: Time.current,
      status: "pending"
    )

    WaitlistMailer.joined(entry).deliver_later

    Result.new(success?: true, entry: entry)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success?: false, error: e.message)
  end

  def self.leave(entry:)
    entry.cancel!
    Result.new(success?: true, entry: entry)
  rescue => e
    Result.new(success?: false, error: e.message)
  end

  def self.promote_next(studio_class:)
    return unless studio_class.spots_remaining > 0

    entry = studio_class.waitlist_entries.pending.ordered.first
    return unless entry

    user = entry.user

    # Check if user can still reserve
    unless user.can_reserve?
      entry.expire!
      # Try next person
      return promote_next(studio_class: studio_class)
    end

    result = ReservationService.reserve(user: user, studio_class: studio_class)

    if result.success?
      entry.promote!
      WaitlistMailer.promoted(entry).deliver_later
      result
    else
      entry.expire!
      promote_next(studio_class: studio_class)
    end
  end
end
