require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @organizer = User.create!(
      name: "企画者",
      display_name: "Organizer",
      email: "organizer@example.com",
      password: "Password1",
      password_confirmation: "Password1"
    )

    @artist = Artist.create!(name: "The Rockets", genre: "Rock", kind: :band)
  end

  test "discounted_price applies registered discounts in priority order" do
    event = @organizer.events.create!(name: "テストイベント", event_date: Date.current + 1, venue: "CLUB", event_fee: 2500, drink_fee: 500)
    Discount.create!(name: "早割", kind: :percentage, value: 10, priority: 2)
    Discount.create!(name: "学割", kind: :fixed, value: 500, priority: 1)
    Discount.create!(name: "取置", kind: :fixed, value: 200, priority: 0)

    event.update!(discount_ids: Discount.pluck(:id))

    assert_equal 2070, event.discounted_price
  end

  test "cannot publish without timetable" do
    event = @organizer.events.create!(name: "テストイベント", event_date: Date.current + 1, venue: "CLUB", event_fee: 2500, drink_fee: 500)

    assert_not event.update(state: :published)
    assert_includes event.errors[:timetable_slots], "が1枠以上必要です"
  end

  test "publishes with valid timetable slot" do
    event = @organizer.events.create!(name: "テストイベント", event_date: Date.current + 1, venue: "CLUB", event_fee: 2500, drink_fee: 500)
    timetable = event.event_timetables.create!(stage_name: "Main")
    timetable.timetable_slots.create!(
      artist: @artist,
      start_time: Time.zone.parse("2024-01-01 18:00"),
      end_time: Time.zone.parse("2024-01-01 18:30"),
      changeover: false
    )

    assert event.update(state: :published)
  end
end
