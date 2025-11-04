class AddFeeBreakdownToEvents < ActiveRecord::Migration[8.1]
  def up
    add_column :events, :event_fee, :integer, default: 0, null: false
    add_column :events, :drink_fee, :integer, default: 0, null: false

    execute <<~SQL
      UPDATE events
      SET event_fee = entrance_fee,
          drink_fee = 0
    SQL

    add_check_constraint :events, "event_fee >= 0 AND event_fee <= 50000", name: "check_events_event_fee_range"
    add_check_constraint :events, "drink_fee >= 0 AND drink_fee <= 50000", name: "check_events_drink_fee_range"
    add_check_constraint :events, "(event_fee + drink_fee) <= 100000", name: "check_events_fee_total_range"
  end

  def down
    remove_check_constraint :events, name: "check_events_fee_total_range"
    remove_check_constraint :events, name: "check_events_event_fee_range"
    remove_check_constraint :events, name: "check_events_drink_fee_range"
    remove_column :events, :event_fee
    remove_column :events, :drink_fee
  end
end
