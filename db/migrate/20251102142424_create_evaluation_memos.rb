class CreateEvaluationMemos < ActiveRecord::Migration[8.1]
  def change
    create_table :evaluation_memos do |t|
      t.references :event, null: true, foreign_key: true
      t.string :category, null: false
      t.text :note, null: false
      t.integer :source_row
      t.json :data, null: false, default: {}

      t.timestamps
    end
    add_index :evaluation_memos, :category
  end
end
