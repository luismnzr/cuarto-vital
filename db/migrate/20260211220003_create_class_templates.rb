class CreateClassTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :class_templates do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.string :style
      t.string :level, null: false, default: "all_levels"
      t.text :description
      t.integer :default_duration, null: false, default: 60
      t.integer :default_capacity, null: false, default: 20
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :class_templates, :active
  end
end
