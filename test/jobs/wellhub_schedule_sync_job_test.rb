require "test_helper"

class WellhubScheduleSyncJobTest < ActiveSupport::TestCase
  setup do
    ENV["WELLHUB_API_KEY"] = "test_key_123"
    StudioSetting.set("wellhub_enabled", "true")
  end

  test "perform calls sync_all when API key present and wellhub enabled" do
    synced = false

    mock_redis = ->(&block) {
      conn = Minitest::Mock.new
      conn.expect(:set, true, [String, String], nx: true, ex: Integer)
      conn.expect(:del, 1, [String])
      block.call(conn)
    }

    Sidekiq.stub(:redis, mock_redis) do
      WellhubScheduleSyncService.stub(:sync_all, -> { synced = true }) do
        WellhubScheduleSyncJob.new.perform
      end
    end

    assert synced
  end

  test "perform skips when WELLHUB_API_KEY is missing" do
    ENV.delete("WELLHUB_API_KEY")

    synced = false
    WellhubScheduleSyncService.stub(:sync_all, -> { synced = true }) do
      WellhubScheduleSyncJob.new.perform
    end

    assert_not synced
  ensure
    ENV["WELLHUB_API_KEY"] = "test_key_123"
  end

  test "perform skips when wellhub is disabled" do
    StudioSetting.set("wellhub_enabled", "false")

    synced = false
    WellhubScheduleSyncService.stub(:sync_all, -> { synced = true }) do
      WellhubScheduleSyncJob.new.perform
    end

    assert_not synced
  end

  test "perform skips when lock cannot be acquired" do
    synced = false

    # Simulate NX returning false (lock already held)
    mock_redis = ->(&block) {
      conn = Minitest::Mock.new
      conn.expect(:set, false, [String, String], nx: true, ex: Integer)
      block.call(conn)
    }

    Sidekiq.stub(:redis, mock_redis) do
      WellhubScheduleSyncService.stub(:sync_all, -> { synced = true }) do
        WellhubScheduleSyncJob.new.perform
      end
    end

    assert_not synced, "Should not sync when lock is held by another instance"
  end

  test "perform releases lock after completion" do
    lock_deleted = false

    call_count = 0
    mock_redis = ->(&block) {
      conn = Minitest::Mock.new
      call_count += 1
      if call_count == 1
        # First call: acquire lock
        conn.expect(:set, true, [String, String], nx: true, ex: Integer)
      else
        # Second call: release lock
        conn.expect(:del, 1, [String])
        lock_deleted = true
      end
      block.call(conn)
    }

    Sidekiq.stub(:redis, mock_redis) do
      WellhubScheduleSyncService.stub(:sync_all, -> {}) do
        WellhubScheduleSyncJob.new.perform
      end
    end

    assert lock_deleted, "Lock should be released after job completes"
  end

  test "perform releases lock even when sync_all raises" do
    lock_deleted = false

    call_count = 0
    mock_redis = ->(&block) {
      conn = Minitest::Mock.new
      call_count += 1
      if call_count == 1
        conn.expect(:set, true, [String, String], nx: true, ex: Integer)
      else
        conn.expect(:del, 1, [String])
        lock_deleted = true
      end
      block.call(conn)
    }

    Sidekiq.stub(:redis, mock_redis) do
      WellhubScheduleSyncService.stub(:sync_all, -> { raise StandardError, "boom" }) do
        assert_raises(StandardError) do
          WellhubScheduleSyncJob.new.perform
        end
      end
    end

    assert lock_deleted, "Lock should be released even after error"
  end
end
