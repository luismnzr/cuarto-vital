class CreateSubscriptionPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :subscription_plans do |t|
      t.string :name, null: false
      t.decimal :price, null: false, precision: 10, scale: 2
      t.string :interval, null: false, default: "monthly"
      t.string :stripe_price_id
      t.text :description
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :subscription_plans, :active
    add_index :subscription_plans, :stripe_price_id, unique: true
  end
end
