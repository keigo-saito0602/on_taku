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

  test "discounted_price follows category sequence and percentage-first rule" do
    event = build_event(event_fee: 3000, drink_fee: 500)
    set_discount = create_discount(
      name: "セット割500",
      kind: :fixed,
      value: 500,
      priority: 0,
      category: :set,
      scope: :ticket
    )
    student_discount = create_discount(
      name: "学割10%",
      kind: :percentage,
      value: 10,
      priority: 1,
      category: :student,
      scope: :ticket
    )
    early_discount = create_discount(
      name: "早割5%",
      kind: :percentage,
      value: 5,
      priority: 2,
      category: :early,
      scope: :ticket
    )

    event.update!(discount_ids: [ set_discount.id, student_discount.id, early_discount.id ])

    breakdown = event.discount_breakdown
    assert_equal 2637, breakdown.total_after
    assert_equal %w[set student early], breakdown.applied_discounts.map { |entry| entry[:category] }
  end

  test "student and staff discounts are exclusive and prefer larger savings" do
    event = build_event(event_fee: 4000, drink_fee: 0)
    student = create_discount(
      name: "学生20%",
      kind: :percentage,
      value: 20,
      priority: 1,
      category: :student,
      scope: :ticket
    )
    staff = create_discount(
      name: "スタッフ1000円",
      kind: :fixed,
      value: 1000,
      priority: 0,
      category: :staff,
      scope: :ticket
    )

    event.update!(discount_ids: [ student.id, staff.id ])

    breakdown = event.discount_breakdown
    assert_equal staff.id, breakdown.applied_discounts.first[:id], "Expect staff discount to be chosen for higher savings"
    assert_equal 3000, breakdown.total_after
  end

  test "same scope exclusive rule prevents overlapping discounts" do
    event = build_event(event_fee: 2000, drink_fee: 1000)
    first = create_discount(
      name: "ドリンク10%",
      kind: :percentage,
      value: 10,
      priority: 0,
      category: :custom,
      scope: :drink,
      stacking_rule: :same_scope
    )
    second = create_discount(
      name: "ドリンク500円",
      kind: :fixed,
      value: 500,
      priority: 1,
      category: :custom,
      scope: :drink,
      stacking_rule: :same_scope
    )

    event.update!(discount_ids: [ first.id, second.id ])

    breakdown = event.discount_breakdown
    assert_equal 900, breakdown.drink_after
    assert_equal 1, breakdown.applied_discounts.size
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

  private

  def build_event(event_fee:, drink_fee:)
    @organizer.events.create!(
      name: "テストイベント",
      event_date: Date.current + 1,
      venue: "CLUB",
      event_fee:,
      drink_fee:
    )
  end

  def create_discount(**attrs)
    defaults = {
      description: "",
      stacking_rule: :stackable,
      scope: :ticket,
      published: true,
      minimum_amount: 0,
      minimum_quantity: 0,
      usage_limit_per_user: 0,
      usage_limit_total: 0
    }
    Discount.create!(defaults.merge(attrs))
  end
end
