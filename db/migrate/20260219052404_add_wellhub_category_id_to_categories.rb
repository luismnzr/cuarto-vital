class AddWellhubCategoryIdToCategories < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :wellhub_category_id, :string
  end
end
