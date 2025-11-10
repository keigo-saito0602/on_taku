class DropEvaluationMemos < ActiveRecord::Migration[8.1]
  def change
    drop_table :evaluation_memos do |t|
      t.references :event, null: true, foreign_key: true
      t.string :category, null: false
      t.text :note, null: false
      t.integer :source_row
      t.json :data, null: false, default: {}
      t.timestamps
      t.index :category
    end
  end
end
