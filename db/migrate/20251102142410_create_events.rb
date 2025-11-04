class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :organizer, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.date :event_date, null: false
      t.string :venue, null: false
      t.integer :entrance_fee, null: false, default: 0
      t.time :door_time
      t.time :start_time
      t.integer :state, null: false, default: 0
      t.text :description

      t.timestamps
    end
    add_check_constraint :events, "entrance_fee >= 0 AND entrance_fee <= 100000", name: "check_events_entrance_fee_range"
  end
end
