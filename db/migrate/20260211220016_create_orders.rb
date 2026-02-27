class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :user, foreign_key: true
      t.decimal :total, null: false, precision: 10, scale: 2
      t.string :status, null: false, default: "pending"
      t.text :notes
      t.string :stripe_payment_intent_id
      t.string :payment_method, null: false, default: "cash"

      t.timestamps
    end

    add_index :orders, :status
  end
end
