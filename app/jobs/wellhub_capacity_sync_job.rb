class WellhubCapacitySyncJob < ApplicationJob
  queue_as :default

  def perform(studio_class_id)
    return unless StudioSetting.wellhub_enabled?

    studio_class = StudioClass.find_by(id: studio_class_id)
    return unless studio_class&.wellhub_slot_id

    template = studio_class.class_template
    return unless template&.wellhub_class_id

    WellhubClient.update_slot(
      gym_id: StudioSetting.wellhub_gym_id,
      class_id: template.wellhub_class_id,
      slot_id: studio_class.wellhub_slot_id,
      attributes: {
        total_booked: studio_class.capacity - studio_class.spots_remaining,
        total_capacity: studio_class.capacity
      }
    )
  rescue WellhubClient::Error => e
    Rails.logger.error "WellhubCapacitySyncJob failed for class #{studio_class_id}: #{e.message}"
  end
end
