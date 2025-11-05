class AddSlotKindToTimetableSlots < ActiveRecord::Migration[8.1]
  def change
    add_column :timetable_slots, :slot_kind, :string, null: false, default: "performance"

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE timetable_slots
          SET slot_kind = CASE
            WHEN changeover = 1 THEN 'changeover'
            WHEN artist_id IS NULL OR artist_id = 0 THEN 'other'
            ELSE 'performance'
          END
        SQL
      end
    end

    add_index :timetable_slots, :slot_kind
  end
end
