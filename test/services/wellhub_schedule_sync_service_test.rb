require "test_helper"

class WellhubScheduleSyncServiceTest < ActiveSupport::TestCase
  setup do
    @category = create(:category, wellhub_category_id: 42)
    @template = create(:class_template, category: @category, name: "Vinyasa Flow", description: "A dynamic class")
    @teacher = create(:user, :teacher)

    StudioSetting.set("wellhub_enabled", "true")
    StudioSetting.set("wellhub_gym_id", "gym_123")
    StudioSetting.set("wellhub_product_id", "7")

    @saved_wellhub_gym_id = ENV["WELLHUB_GYM_ID"]
  end

  teardown do
    ENV["WELLHUB_GYM_ID"] = @saved_wellhub_gym_id
  end

  # --- sync_all ---

  test "sync_all does nothing when wellhub is disabled" do
    StudioSetting.set("wellhub_enabled", "false")

    # If sync_classes or sync_slots ran, they'd call the API without stubs and error
    WellhubScheduleSyncService.sync_all
    assert_nil @template.reload.wellhub_class_id
  end

  test "sync_all calls sync_classes and sync_slots" do
    classes_called = false
    slots_called = false

    WellhubScheduleSyncService.stub(:sync_classes, -> { classes_called = true }) do
      WellhubScheduleSyncService.stub(:sync_slots, -> { slots_called = true }) do
        WellhubScheduleSyncService.sync_all
      end
    end

    assert classes_called
    assert slots_called
  end

  # --- sync_classes: create ---

  test "sync_classes creates new Wellhub class for template without wellhub_class_id" do
    create_response = { "classes" => [ { "id" => 999, "name" => "Vinyasa Flow" } ] }

    captured_attrs = nil
    mock_create = ->(gym_id:, attributes:) {
      captured_attrs = attributes
      create_response
    }

    WellhubClient.stub(:create_class, mock_create) do
      WellhubScheduleSyncService.sync_classes
    end

    # Verify the class was created with correct WellHub API payload
    assert_not_nil captured_attrs
    klass = captured_attrs[:classes][0]
    assert_equal "Vinyasa Flow", klass[:name]
    assert_equal "A dynamic class", klass[:description]
    assert_equal true, klass[:bookable]
    assert_equal true, klass[:visible]
    assert_equal [ 42 ], klass[:categories]
    assert_equal 7, klass[:product_id]
    assert_equal @template.id.to_s, klass[:reference]

    # Verify template was updated with returned ID
    assert_equal "999", @template.reload.wellhub_class_id
  end

  test "sync_classes updates existing Wellhub class for template with wellhub_class_id" do
    @template.update!(wellhub_class_id: "existing_456")

    captured_attrs = nil
    mock_update = ->(gym_id:, class_id:, attributes:) {
      captured_attrs = attributes
      assert_equal "existing_456", class_id
      nil
    }

    WellhubClient.stub(:update_class, mock_update) do
      WellhubScheduleSyncService.sync_classes
    end

    # Update payload is flat (not wrapped in classes array)
    assert_not_nil captured_attrs
    assert_equal "Vinyasa Flow", captured_attrs[:name]
    assert_equal true, captured_attrs[:bookable]
    assert_equal [ 42 ], captured_attrs[:categories]
  end

  test "sync_classes skips templates without mapped wellhub_category_id" do
    @category.update!(wellhub_category_id: nil)

    # Should not call any API — if it does, it'll blow up without stubs
    WellhubScheduleSyncService.sync_classes
    assert_nil @template.reload.wellhub_class_id
  end

  test "sync_classes skips inactive templates" do
    @template.update!(active: false)

    WellhubScheduleSyncService.sync_classes
    assert_nil @template.reload.wellhub_class_id
  end

  test "sync_classes returns early when gym_id is blank" do
    StudioSetting.set("wellhub_gym_id", "")
    ENV.delete("WELLHUB_GYM_ID")

    WellhubScheduleSyncService.sync_classes
    assert_nil @template.reload.wellhub_class_id
  end

  test "sync_classes continues when one template fails" do
    category2 = create(:category, wellhub_category_id: 43)
    template2 = create(:class_template, category: category2, name: "Pilates")

    call_count = 0
    mock_create = ->(gym_id:, attributes:) {
      call_count += 1
      raise WellhubClient::Error.new("API error", status: 500) if call_count == 1
      { "classes" => [ { "id" => 888 } ] }
    }

    WellhubClient.stub(:create_class, mock_create) do
      WellhubScheduleSyncService.sync_classes
    end

    # One should have failed, the other should have succeeded
    templates = [ @template.reload, template2.reload ]
    synced = templates.select { |t| t.wellhub_class_id.present? }
    assert_equal 1, synced.count
  end

  # --- sync_slots ---

  test "sync_slots creates slot for scheduled class with synced template" do
    @template.update!(wellhub_class_id: "wh_class_1")
    studio_class = create(:studio_class,
      class_template: @template,
      teacher: @teacher,
      date: Date.current + 1.day,
      start_time: Time.zone.parse("09:00"),
      end_time: Time.zone.parse("10:00"),
      duration: 60,
      capacity: 20,
      spots_remaining: 15,
      status: "scheduled",
      wellhub_slot_id: nil
    )

    captured_attrs = nil
    mock_create_slot = ->(gym_id:, class_id:, attributes:) {
      captured_attrs = attributes
      assert_equal "gym_123", gym_id
      assert_equal "wh_class_1", class_id
      { "id" => 5555 }
    }

    WellhubClient.stub(:create_slot, mock_create_slot) do
      WellhubScheduleSyncService.sync_slots
    end

    # Verify slot payload matches WellHub API spec
    assert_not_nil captured_attrs
    assert captured_attrs[:occur_date].present?, "occur_date should be present"
    assert_equal 60, captured_attrs[:length_in_minutes]
    assert_equal 20, captured_attrs[:total_capacity]
    assert_equal 5, captured_attrs[:total_booked]
    assert_equal 1, captured_attrs[:status]
    assert_equal 7, captured_attrs[:product_id]

    # Verify occur_date is ISO 8601
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, captured_attrs[:occur_date])

    # Verify slot_id was stored
    assert_equal "5555", studio_class.reload.wellhub_slot_id
  end

  test "sync_slots skips classes that already have a wellhub_slot_id" do
    @template.update!(wellhub_class_id: "wh_class_1")
    sc = create(:studio_class,
      class_template: @template,
      teacher: @teacher,
      date: Date.current + 1.day,
      status: "scheduled",
      wellhub_slot_id: "already_synced"
    )

    # Should not call API — no stub needed
    WellhubScheduleSyncService.sync_slots
    assert_equal "already_synced", sc.reload.wellhub_slot_id
  end

  test "sync_slots skips classes whose template has no wellhub_class_id" do
    # Template not yet synced to WellHub
    assert_nil @template.wellhub_class_id

    sc = create(:studio_class,
      class_template: @template,
      teacher: @teacher,
      date: Date.current + 1.day,
      status: "scheduled",
      wellhub_slot_id: nil
    )

    WellhubScheduleSyncService.sync_slots
    assert_nil sc.reload.wellhub_slot_id
  end

  test "sync_slots skips past classes" do
    @template.update!(wellhub_class_id: "wh_class_1")
    sc = create(:studio_class,
      class_template: @template,
      teacher: @teacher,
      date: Date.current - 1.day,
      status: "scheduled",
      wellhub_slot_id: nil
    )

    WellhubScheduleSyncService.sync_slots
    assert_nil sc.reload.wellhub_slot_id
  end

  test "sync_slots skips cancelled classes" do
    @template.update!(wellhub_class_id: "wh_class_1")
    sc = create(:studio_class,
      class_template: @template,
      teacher: @teacher,
      date: Date.current + 1.day,
      status: "cancelled",
      wellhub_slot_id: nil
    )

    WellhubScheduleSyncService.sync_slots
    assert_nil sc.reload.wellhub_slot_id
  end

  test "sync_slots continues when one class fails" do
    @template.update!(wellhub_class_id: "wh_class_1")
    sc1 = create(:studio_class, class_template: @template, teacher: @teacher,
      date: Date.current + 1.day, status: "scheduled", wellhub_slot_id: nil)
    sc2 = create(:studio_class, class_template: @template, teacher: @teacher,
      date: Date.current + 2.days, status: "scheduled", wellhub_slot_id: nil)

    call_count = 0
    mock_create_slot = ->(gym_id:, class_id:, attributes:) {
      call_count += 1
      raise WellhubClient::Error.new("timeout", status: 504) if call_count == 1
      { "id" => 7777 }
    }

    WellhubClient.stub(:create_slot, mock_create_slot) do
      WellhubScheduleSyncService.sync_slots
    end

    synced = [ sc1.reload, sc2.reload ].select { |sc| sc.wellhub_slot_id.present? }
    assert_equal 1, synced.count
  end

  test "sync_slots uses studio timezone for slot occur_date" do
    StudioSetting.set("studio_timezone", "America/New_York")
    @template.update!(wellhub_class_id: "wh_class_tz")
    studio_class = create(:studio_class,
      class_template: @template,
      teacher: @teacher,
      date: Date.current + 1.day,
      start_time: Time.zone.parse("09:00"),
      end_time: Time.zone.parse("10:00"),
      duration: 60,
      capacity: 20,
      spots_remaining: 15,
      status: "scheduled",
      wellhub_slot_id: nil
    )

    captured_attrs = nil
    mock_create_slot = ->(gym_id:, class_id:, attributes:) {
      captured_attrs = attributes
      { "id" => 9999 }
    }

    WellhubClient.stub(:create_slot, mock_create_slot) do
      WellhubScheduleSyncService.sync_slots
    end

    # The occur_date should reflect the New York timezone offset
    parsed = Time.parse(captured_attrs[:occur_date])
    eastern = ActiveSupport::TimeZone["America/New_York"]
    expected = eastern.parse("#{studio_class.date} 09:00")
    assert_equal expected.utc, parsed.utc
  ensure
    StudioSetting.set("studio_timezone", "America/Mexico_City")
  end

  test "sync_slots returns early when gym_id is blank" do
    StudioSetting.set("wellhub_gym_id", "")
    ENV.delete("WELLHUB_GYM_ID")

    @template.update!(wellhub_class_id: "wh_class_1")
    sc = create(:studio_class, class_template: @template, teacher: @teacher,
      date: Date.current + 1.day, status: "scheduled", wellhub_slot_id: nil)

    WellhubScheduleSyncService.sync_slots
    assert_nil sc.reload.wellhub_slot_id
  end
end
