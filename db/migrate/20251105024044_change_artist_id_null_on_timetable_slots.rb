class ChangeArtistIdNullOnTimetableSlots < ActiveRecord::Migration[8.1]
  def up
    change_column_null :timetable_slots, :artist_id, true
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot enforce NOT NULL once optional slots exist"
  end
end
