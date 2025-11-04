class CreateDiscounts < ActiveRecord::Migration[8.1]
  def change
    create_table :discounts do |t|
      t.string :name, null: false
      t.string :kind, null: false
      t.integer :value, null: false, default: 0
      t.text :description
      t.integer :priority, null: false, default: 0

      t.timestamps
    end

    add_index :discounts, :name, unique: true
    add_index :discounts, :priority
  end
end
