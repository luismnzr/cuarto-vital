class CreateWaitlistEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :waitlist_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :studio_class, null: false, foreign_key: true
      t.integer :position, null: false
      t.datetime :joined_at, null: false
      t.datetime :promoted_at
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :waitlist_entries, [:user_id, :studio_class_id], unique: true, name: "index_waitlist_entries_on_user_and_class"
    add_index :waitlist_entries, [:studio_class_id, :position]
    add_index :waitlist_entries, :status
  end
end
