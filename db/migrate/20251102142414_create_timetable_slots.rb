class CreateTimetableSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :timetable_slots do |t|
      t.references :event, null: false, foreign_key: true
      t.references :artist, null: false, foreign_key: true
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :stage_name

      t.timestamps
    end
    add_index :timetable_slots, [:event_id, :start_time]
  end
end
