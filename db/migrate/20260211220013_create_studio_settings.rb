class CreateStudioSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :studio_settings do |t|
      t.string :key, null: false
      t.text :value

      t.timestamps
    end

    add_index :studio_settings, :key, unique: true
  end
end
