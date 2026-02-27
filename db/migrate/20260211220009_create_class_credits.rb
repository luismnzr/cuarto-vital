class CreateClassCredits < ActiveRecord::Migration[7.2]
  def change
    create_table :class_credits do |t|
      t.references :user_package, null: false, foreign_key: true
      t.datetime :used_at

      t.timestamps
    end
  end
end
