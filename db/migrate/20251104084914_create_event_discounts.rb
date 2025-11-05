class CreateEventDiscounts < ActiveRecord::Migration[8.1]
  def change
    create_table :event_discounts do |t|
      t.references :event, null: false, foreign_key: true
      t.references :discount, null: false, foreign_key: true

      t.timestamps
    end

    add_index :event_discounts, [ :event_id, :discount_id ], unique: true
  end
end
