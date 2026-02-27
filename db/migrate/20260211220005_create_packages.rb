class CreatePackages < ActiveRecord::Migration[7.2]
  def change
    create_table :packages do |t|
      t.string :name, null: false
      t.decimal :price, null: false, precision: 10, scale: 2
      t.integer :credit_count, null: false
      t.integer :expiration_days, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.integer :sort_order, null: false, default: 0

      t.timestamps
    end

    add_index :packages, :active
  end
end
