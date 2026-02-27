class CreateStudioClasses < ActiveRecord::Migration[7.2]
  def change
    create_table :studio_classes do |t|
      t.references :class_template, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.integer :duration, null: false
      t.integer :capacity, null: false
      t.integer :spots_remaining, null: false
      t.string :status, null: false, default: "scheduled"

      t.timestamps
    end

    add_index :studio_classes, [:date, :start_time]
    add_index :studio_classes, :status
    # teacher_id index already created by t.references
  end
end
