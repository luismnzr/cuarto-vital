class ShiftClassTimesToLocalTimezone < ActiveRecord::Migration[7.2]
  def up
    # Existing start_time/end_time values were stored as UTC wall-clock times
    # (e.g. 07:00 meaning 7 AM local). Now that the app timezone is CST (UTC-6),
    # Rails reads them as UTC and converts to CST, shifting them by -6 hours.
    # Adding 6 hours to the stored values compensates so Rails displays correctly.
    execute <<~SQL
      UPDATE studio_classes
      SET start_time = start_time + INTERVAL '6 hours',
          end_time = end_time + INTERVAL '6 hours'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE studio_classes
      SET start_time = start_time - INTERVAL '6 hours',
          end_time = end_time - INTERVAL '6 hours'
    SQL
  end
end
