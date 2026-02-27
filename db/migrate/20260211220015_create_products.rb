class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, null: false, precision: 10, scale: 2
      t.integer :stock_quantity, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :products, :active
  end
end
