class CreateExternalCheckins < ActiveRecord::Migration[7.2]
  def change
    create_table :external_checkins do |t|
      t.string :user_identifier, null: false
      t.string :platform, null: false
      t.references :studio_class, null: false, foreign_key: true
      t.datetime :checked_in_at, null: false
      t.boolean :validated, null: false, default: false
      t.string :external_reference_id

      t.timestamps
    end

    add_index :external_checkins, :platform
    add_index :external_checkins, [:studio_class_id, :platform]
  end
end
