class AddWellhubIntegrationFields < ActiveRecord::Migration[7.2]
  def change
    # Wellhub class ID on templates (one template = one Wellhub "class")
    add_column :class_templates, :wellhub_class_id, :string
    add_index :class_templates, :wellhub_class_id, unique: true

    # Wellhub slot ID on studio classes (one studio_class = one Wellhub "slot")
    add_column :studio_classes, :wellhub_slot_id, :string
    add_index :studio_classes, :wellhub_slot_id, unique: true

    # Track Wellhub bookings separately from internal reservations
    create_table :wellhub_bookings do |t|
      t.references :studio_class, null: false, foreign_key: true
      t.string :booking_number, null: false
      t.string :gympass_id, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :booked_at, null: false
      t.datetime :responded_at
      t.datetime :cancelled_at
      t.datetime :checked_in_at

      t.timestamps
    end

    add_index :wellhub_bookings, :booking_number, unique: true
    add_index :wellhub_bookings, :gympass_id
    add_index :wellhub_bookings, [:studio_class_id, :gympass_id]
  end
end
