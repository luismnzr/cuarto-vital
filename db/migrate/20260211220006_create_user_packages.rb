class CreateUserPackages < ActiveRecord::Migration[7.2]
  def change
    create_table :user_packages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :package, null: false, foreign_key: true
      t.datetime :purchased_at, null: false
      t.datetime :expires_at, null: false
      t.integer :credits_remaining, null: false
      t.string :status, null: false, default: "active"
      t.string :stripe_payment_intent_id

      t.timestamps
    end

    add_index :user_packages, [:user_id, :expires_at]
    add_index :user_packages, :status
  end
end
