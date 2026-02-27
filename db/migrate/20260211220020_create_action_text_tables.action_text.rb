# This migration comes from action_text (originally 20180528164100)
class CreateActionTextTables < ActiveRecord::Migration[7.0]
  def change
    create_table :action_text_rich_texts, id: :bigint do |t|
      t.string     :name, null: false
      t.text       :body, size: :long
      t.references :record, null: false, polymorphic: true, index: false, type: :bigint

      t.timestamps

      t.index [ :record_type, :record_id, :name ], name: :index_action_text_rich_texts_uniqueness, unique: true
    end
  end
end
