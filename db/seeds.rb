# frozen_string_literal: true

ActiveRecord::Base.transaction do
  organizer = User.find_or_create_by!(email: "organizer@example.com") do |user|
    user.name = "企画担当"
    user.display_name = "Organizer"
    user.password = "Password1"
    user.password_confirmation = "Password1"
  end

  reviewer = User.find_or_create_by!(email: "reviewer@example.com") do |user|
    user.name = "評価担当"
    user.display_name = "Reviewer"
    user.role = :reviewer
    user.password = "Password1"
    user.password_confirmation = "Password1"
  end

  rock_band = Artist.find_or_create_by!(name: "The Rockets") do |artist|
    artist.genre = "Rock"
    artist.kind = :band
    artist.official_link = "https://example.com/rockets"
  end

  rock_band.social_links.find_or_create_by!(label: "Website", url: "https://example.com/rockets")
  rock_band.social_links.find_or_create_by!(label: "Twitter", url: "https://twitter.com/rockets")
  rock_band.members.find_or_create_by!(name: "Alice", instrument: "Vocal", role: "Leader")
  rock_band.members.find_or_create_by!(name: "Bob", instrument: "Guitar")

  dj = Artist.find_or_create_by!(name: "DJ Sample") do |artist|
    artist.genre = "House"
    artist.kind = :dj
    artist.official_link = "https://example.com/dj-sample"
  end
  dj.social_links.find_or_create_by!(label: "SoundCloud", url: "https://soundcloud.com/dj-sample")

  event = organizer.events.find_or_initialize_by(name: "Rails Testing Night")
  event.assign_attributes(
    event_date: Date.current + 14,
    venue: "Shibuya Club",
    event_fee: 2500,
    drink_fee: 500,
    description: "テスト設計の成果を発表するショーケースイベント"
  )
  event.save!

  early = Discount.find_or_create_by!(name: "早割") do |discount|
    discount.kind = :percentage
    discount.value = 10
    discount.priority = 2
    discount.description = "公開後1週間以内の購入で10%オフ"
  end
  student = Discount.find_or_create_by!(name: "学割") do |discount|
    discount.kind = :fixed
    discount.value = 500
    discount.priority = 1
    discount.description = "学生証提示で500円引き"
  end
  reservation = Discount.find_or_create_by!(name: "取置") do |discount|
    discount.kind = :fixed
    discount.value = 200
    discount.priority = 0
    discount.description = "事前取置で200円引き"
  end

  event.update!(discount_ids: [ early.id, student.id, reservation.id ])

  timetable = event.event_timetables.find_or_create_by!(stage_name: "Main Stage") do |t|
    t.position = 0
    t.name = "Main Stage"
  end

  unless timetable.timetable_slots.exists?
    timetable.timetable_slots.create!(
      artist: rock_band,
      start_time: Time.zone.parse("18:00"),
      end_time: Time.zone.parse("18:25")
    )

    timetable.timetable_slots.create!(
      artist: dj,
      start_time: Time.zone.parse("18:30"),
      end_time: Time.zone.parse("18:55")
    )
  end

  EvaluationMemo.find_or_create_by!(event:, category: "テスト設計", note: "ディシジョンテーブルを用いて抜け漏れをチェック")

  puts "Seed data ready. Organizer: organizer@example.com / Password1"
  puts "Reviewer: reviewer@example.com / Password1"
end
