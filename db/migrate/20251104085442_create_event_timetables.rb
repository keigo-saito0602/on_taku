class CreateEventTimetables < ActiveRecord::Migration[8.1]
  def change
    create_table :event_timetables do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name
      t.string :stage_name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :event_timetables, [:event_id, :position]
  end
end
