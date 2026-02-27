class AddTeacherProfileFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :bio, :text
    add_column :users, :styles_taught, :text
  end
end
