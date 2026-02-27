class AddScheduleToClassTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :class_templates, :day_of_week, :integer
    add_column :class_templates, :default_start_time, :time
    add_reference :class_templates, :teacher, null: true, foreign_key: { to_table: :users }
  end
end
