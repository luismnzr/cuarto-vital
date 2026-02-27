require "test_helper"

class StudioClassCapacitySyncTest < ActiveSupport::TestCase
  setup do
    @template = create(:class_template, wellhub_class_id: "wh_class_1")
    @studio_class = create(:studio_class,
      class_template: @template,
      wellhub_slot_id: "wh_slot_1",
      capacity: 20,
      spots_remaining: 15
    )
    StudioSetting.set("wellhub_enabled", "true")
  end

  test "wellhub_capacity_changed? returns true when spots_remaining changes" do
    @studio_class.update!(spots_remaining: 14)
    assert @studio_class.send(:wellhub_capacity_changed?),
      "Should detect spots_remaining change"
  end

  test "wellhub_capacity_changed? returns true when capacity changes" do
    @studio_class.update!(capacity: 25)
    assert @studio_class.send(:wellhub_capacity_changed?),
      "Should detect capacity change"
  end

  test "wellhub_capacity_changed? returns false when class has no wellhub_slot_id" do
    @studio_class.update_columns(wellhub_slot_id: nil)
    @studio_class.update!(spots_remaining: 10)
    assert_not @studio_class.send(:wellhub_capacity_changed?),
      "Should not detect change without wellhub_slot_id"
  end

  test "wellhub_capacity_changed? returns false for non-capacity field changes" do
    @studio_class.update!(date: Date.current + 5.days)
    assert_not @studio_class.send(:wellhub_capacity_changed?),
      "Should not detect change for non-capacity fields"
  end

  test "enqueue_wellhub_capacity_sync calls perform_later with class id" do
    enqueued_id = nil
    WellhubCapacitySyncJob.stub(:perform_later, ->(id) { enqueued_id = id }) do
      @studio_class.send(:enqueue_wellhub_capacity_sync)
    end
    assert_equal @studio_class.id, enqueued_id
  end
end
