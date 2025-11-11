class AddAdvancedFieldsToDiscounts < ActiveRecord::Migration[8.1]
  def change
    add_column :discounts, :category, :string, null: false, default: "custom"
    add_column :discounts, :scope, :string, null: false, default: "total"
    add_column :discounts, :stacking_rule, :string, null: false, default: "stackable"
    add_column :discounts, :published, :boolean, null: false, default: true
    add_column :discounts, :start_at, :datetime
    add_column :discounts, :end_at, :datetime
    add_column :discounts, :minimum_amount, :integer, null: false, default: 0
    add_column :discounts, :minimum_quantity, :integer, null: false, default: 0
    add_column :discounts, :usage_limit_per_user, :integer, null: false, default: 0
    add_column :discounts, :usage_limit_total, :integer, null: false, default: 0

    add_index :discounts, :category
    add_index :discounts, :scope
    add_index :discounts, :stacking_rule
    add_index :discounts, :published
    add_index :discounts, :start_at
    add_index :discounts, :end_at
  end
end
