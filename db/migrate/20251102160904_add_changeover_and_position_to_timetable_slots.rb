class AddChangeoverAndPositionToTimetableSlots < ActiveRecord::Migration[8.1]
  def up
    add_column :timetable_slots, :changeover, :boolean, default: false, null: false
    add_column :timetable_slots, :position, :integer

    execute <<~SQL
      UPDATE timetable_slots
      SET position = sub.rn
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY start_time) AS rn
        FROM timetable_slots
      ) sub
      WHERE timetable_slots.id = sub.id
    SQL
  end

  def down
    remove_column :timetable_slots, :changeover
    remove_column :timetable_slots, :position
  end
end
