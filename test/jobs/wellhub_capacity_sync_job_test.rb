require "test_helper"

class WellhubCapacitySyncJobTest < ActiveSupport::TestCase
  setup do
    @template = create(:class_template, wellhub_class_id: "wh_class_1")
    @studio_class = create(:studio_class,
      class_template: @template,
      wellhub_slot_id: "wh_slot_1",
      capacity: 20,
      spots_remaining: 15
    )
    StudioSetting.set("wellhub_enabled", "true")
    StudioSetting.set("wellhub_gym_id", "gym_test")
  end

  test "perform syncs capacity to Wellhub" do
    synced_attrs = nil

    update_slot_stub = ->(**kwargs) {
      synced_attrs = kwargs[:attributes]
      {}
    }

    WellhubClient.stub(:update_slot, update_slot_stub) do
      WellhubCapacitySyncJob.new.perform(@studio_class.id)
    end

    assert_not_nil synced_attrs
    assert_equal 5, synced_attrs[:total_booked]
    assert_equal 20, synced_attrs[:total_capacity]
  end

  test "perform skips when wellhub is disabled" do
    StudioSetting.set("wellhub_enabled", "false")

    called = false
    WellhubClient.stub(:update_slot, ->(**_) { called = true; {} }) do
      WellhubCapacitySyncJob.new.perform(@studio_class.id)
    end

    assert_not called
  end

  test "perform skips when studio class has no wellhub_slot_id" do
    @studio_class.update_columns(wellhub_slot_id: nil)

    called = false
    WellhubClient.stub(:update_slot, ->(**_) { called = true; {} }) do
      WellhubCapacitySyncJob.new.perform(@studio_class.id)
    end

    assert_not called
  end

  test "perform skips when class template has no wellhub_class_id" do
    @template.update_columns(wellhub_class_id: nil)

    called = false
    WellhubClient.stub(:update_slot, ->(**_) { called = true; {} }) do
      WellhubCapacitySyncJob.new.perform(@studio_class.id)
    end

    assert_not called
  end

  test "perform skips when studio class does not exist" do
    called = false
    WellhubClient.stub(:update_slot, ->(**_) { called = true; {} }) do
      WellhubCapacitySyncJob.new.perform(-1)
    end

    assert_not called
  end

  test "perform handles API errors gracefully" do
    error_stub = ->(**_) { raise WellhubClient::Error.new("timeout", status: 500) }

    WellhubClient.stub(:update_slot, error_stub) do
      assert_nothing_raised do
        WellhubCapacitySyncJob.new.perform(@studio_class.id)
      end
    end
  end
end
