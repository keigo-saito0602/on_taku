require "test_helper"

class TimetableSlotTest < ActiveSupport::TestCase
  setup do
    @organizer = User.create!(
      name: "企画者",
      display_name: "Organizer",
      email: "slot-owner@example.com",
      password: "Password1",
      password_confirmation: "Password1"
    )
    @artist = Artist.create!(name: "DJ Sample", kind: :dj)
    @event = @organizer.events.create!(name: "イベント", event_date: Date.current + 1, venue: "Club", event_fee: 1000, drink_fee: 0)
    @timetable = @event.event_timetables.create!(stage_name: "Main Stage")
  end

  test "valid slot" do
    slot = @timetable.timetable_slots.new(
      artist: @artist,
      start_time: Time.zone.parse("2024-01-01 18:00"),
      end_time: Time.zone.parse("2024-01-01 18:30"),
      changeover: false
    )

    assert slot.valid?
  end

  test "rejects overlapping slot" do
    @timetable.timetable_slots.create!(
      artist: @artist,
      start_time: Time.zone.parse("2024-01-01 18:00"),
      end_time: Time.zone.parse("2024-01-01 18:30")
    )
    slot = @timetable.timetable_slots.new(
      artist: @artist,
      start_time: Time.zone.parse("2024-01-01 18:15"),
      end_time: Time.zone.parse("2024-01-01 18:45")
    )

    assert slot.invalid?
    assert_includes slot.errors[:base], "他の枠と時刻が重複しています"
  end

  test "enforces grid increment" do
    slot = @timetable.timetable_slots.new(
      artist: @artist,
      start_time: Time.zone.parse("2024-01-01 18:07"),
      end_time: Time.zone.parse("2024-01-01 18:37")
    )

    assert slot.invalid?
    assert_includes slot.errors[:base], "5分刻みの時刻を選択してください"
  end

  test "allows overlapping slots on different stages" do
    other_stage = @event.event_timetables.create!(stage_name: "Second Stage")
    @timetable.timetable_slots.create!(
      artist: @artist,
      start_time: Time.zone.parse("2024-01-01 18:00"),
      end_time: Time.zone.parse("2024-01-01 18:30")
    )
    slot = other_stage.timetable_slots.new(
      artist: @artist,
      start_time: Time.zone.parse("2024-01-01 18:15"),
      end_time: Time.zone.parse("2024-01-01 18:45")
    )

    assert slot.valid?
  end
end
