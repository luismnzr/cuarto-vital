class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_payment_intent_id
      t.string :stripe_checkout_session_id
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.string :currency, null: false, default: "mxn"
      t.string :status, null: false, default: "pending"
      t.string :description
      t.string :payable_type
      t.bigint :payable_id

      t.timestamps
    end

    add_index :payments, :stripe_payment_intent_id, unique: true
    add_index :payments, :stripe_checkout_session_id, unique: true
    add_index :payments, [:payable_type, :payable_id]
  end
end
