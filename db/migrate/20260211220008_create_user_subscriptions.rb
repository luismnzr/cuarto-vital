class CreateUserSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :user_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subscription_plan, null: false, foreign_key: true
      t.string :stripe_subscription_id
      t.string :stripe_customer_id
      t.string :status, null: false, default: "active"
      t.datetime :current_period_start
      t.datetime :current_period_end

      t.timestamps
    end

    add_index :user_subscriptions, :stripe_subscription_id, unique: true
    add_index :user_subscriptions, [:user_id, :status]
  end
end
