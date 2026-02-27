class WellhubScheduleSyncService
  class << self
    # Sync all active class templates as Wellhub "classes" and upcoming studio_classes as "slots"
    def sync_all
      return unless StudioSetting.wellhub_enabled?

      sync_classes
      sync_slots
    end

    # Push class templates to Wellhub as "classes" (create new, update existing)
    def sync_classes
      gym_id = StudioSetting.wellhub_gym_id
      return unless gym_id

      ClassTemplate.active.includes(:category).find_each do |template|
        next unless template.category&.wellhub_category_id.present?

        if template.wellhub_class_id.present?
          # Already synced — update name/description/category if changed
          update_class(gym_id, template)
        else
          create_class(gym_id, template)
        end
      rescue WellhubClient::Error => e
        Rails.logger.error "Failed to sync class template #{template.id}: #{e.message}"
      end
    end

    # Push upcoming studio_classes as Wellhub "slots"
    def sync_slots
      gym_id = StudioSetting.wellhub_gym_id
      return unless gym_id

      StudioClass.scheduled
                 .where(wellhub_slot_id: nil)
                 .where("date >= ?", Date.current)
                 .includes(:class_template)
                 .find_each do |studio_class|
        template = studio_class.class_template
        next unless template.wellhub_class_id.present?

        response = WellhubClient.create_slot(
          gym_id: gym_id,
          class_id: template.wellhub_class_id,
          attributes: slot_payload(studio_class)
        )

        studio_class.update!(wellhub_slot_id: response["id"].to_s)
        Rails.logger.info "Synced studio class #{studio_class.id} -> Wellhub slot #{response['id']}"
      rescue WellhubClient::Error => e
        Rails.logger.error "Failed to sync studio class #{studio_class.id}: #{e.message}"
      end
    end

    private

    def create_class(gym_id, template)
      response = WellhubClient.create_class(
        gym_id: gym_id,
        attributes: { classes: [ class_payload(template) ] }
      )

      wellhub_id = response.dig("classes", 0, "id")
      template.update!(wellhub_class_id: wellhub_id.to_s)
      Rails.logger.info "Created Wellhub class for template #{template.id} -> #{wellhub_id}"
    end

    def update_class(gym_id, template)
      WellhubClient.update_class(
        gym_id: gym_id,
        class_id: template.wellhub_class_id,
        attributes: class_payload(template)
      )
    end

    def class_payload(template)
      {
        name: template.name,
        description: template.description || "",
        bookable: true,
        visible: true,
        categories: [ template.category.wellhub_category_id.to_i ],
        product_id: StudioSetting.get("wellhub_product_id").to_i,
        reference: template.id.to_s
      }
    end

    def slot_payload(studio_class)
      tz = ActiveSupport::TimeZone[StudioSetting.studio_timezone]
      starts_at = tz.parse("#{studio_class.date} #{studio_class.start_time.strftime('%H:%M')}")

      {
        occur_date: starts_at.iso8601,
        length_in_minutes: studio_class.duration,
        total_capacity: studio_class.capacity,
        total_booked: studio_class.capacity - studio_class.spots_remaining,
        status: 1,
        product_id: StudioSetting.get("wellhub_product_id").to_i
      }
    end
  end
end
