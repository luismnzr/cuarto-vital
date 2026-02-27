class CreateReservations < ActiveRecord::Migration[7.2]
  def change
    create_table :reservations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :studio_class, null: false, foreign_key: true
      t.references :class_credit, foreign_key: true
      t.string :status, null: false, default: "confirmed"
      t.datetime :cancelled_at
      t.boolean :late_cancel, null: false, default: false

      t.timestamps
    end

    add_index :reservations, [:user_id, :studio_class_id], unique: true, name: "index_reservations_on_user_and_class"
    add_index :reservations, :status
  end
end
