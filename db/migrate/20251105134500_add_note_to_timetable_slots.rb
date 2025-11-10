class AddNoteToTimetableSlots < ActiveRecord::Migration[8.1]
  def change
    add_column :timetable_slots, :note, :text, null: false, default: ""
  end
end
