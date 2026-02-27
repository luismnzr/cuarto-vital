class WaitlistPromotionJob < ApplicationJob
  queue_as :default

  def perform(studio_class_id)
    studio_class = StudioClass.find_by(id: studio_class_id)
    return unless studio_class
    return unless studio_class.spots_remaining > 0

    WaitlistService.promote_next(studio_class: studio_class)
  end
end
