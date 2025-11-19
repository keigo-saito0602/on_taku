class CreateDiscountSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :discount_snapshots do |t|
      t.references :event, null: false, foreign_key: true
      t.json :applied_discounts, null: false, default: []
      t.integer :total_before, null: false, default: 0
      t.integer :total_after, null: false, default: 0
      t.integer :ticket_before, null: false, default: 0
      t.integer :ticket_after, null: false, default: 0
      t.integer :drink_before, null: false, default: 0
      t.integer :drink_after, null: false, default: 0
      t.integer :merch_before, null: false, default: 0
      t.integer :merch_after, null: false, default: 0
      t.string :rounding_mode, null: false, default: "floor"
      t.json :details, null: false, default: {}

      t.timestamps
    end

    add_index :discount_snapshots, %i[event_id created_at]
  end
end
