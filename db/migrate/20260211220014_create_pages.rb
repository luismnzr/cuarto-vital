class CreatePages < ActiveRecord::Migration[7.2]
  def change
    create_table :pages do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.boolean :published, null: false, default: false
      t.integer :sort_order, null: false, default: 0

      t.timestamps
    end

    add_index :pages, :slug, unique: true
    add_index :pages, :published
  end
end
