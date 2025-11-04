class AddEventTimetableToTimetableSlots < ActiveRecord::Migration[8.1]
  class MigrationEvent < ApplicationRecord
    self.table_name = "events"
  end

  class MigrationTimetableSlot < ApplicationRecord
    self.table_name = "timetable_slots"
  end

  class MigrationEventTimetable < ApplicationRecord
    self.table_name = "event_timetables"
  end

  def up
    add_reference :timetable_slots, :event_timetable, foreign_key: true

    MigrationEvent.find_each do |event|
      slots = MigrationTimetableSlot.where(event_id: event.id).order(:position, :start_time)
      next if slots.empty?

      grouped = slots.group_by { |slot| slot.stage_name.presence || "Main" }

      grouped.each.with_index do |(stage_name, stage_slots), index|
        timetable = MigrationEventTimetable.create!(
          event_id: event.id,
          stage_name: stage_name,
          name: stage_name,
          position: index
        )
        stage_slots.each do |slot|
          slot.update_columns(event_timetable_id: timetable.id, stage_name: timetable.stage_name)
        end
      end
    end

    MigrationTimetableSlot.where(event_timetable_id: nil).find_each do |slot|
      timetable = MigrationEventTimetable.create!(
        event_id: slot.event_id,
        stage_name: "Main",
        name: "Main",
        position: 0
      )
      slot.update_columns(event_timetable_id: timetable.id)
    end

    change_column_null :timetable_slots, :event_timetable_id, false
  end

  def down
    remove_reference :timetable_slots, :event_timetable, foreign_key: true
  end
end
