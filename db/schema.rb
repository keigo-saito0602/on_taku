# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_04_144745) do
  create_table "artist_members", force: :cascade do |t|
    t.integer "artist_id", null: false
    t.datetime "created_at", null: false
    t.string "instrument"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["artist_id", "position"], name: "index_artist_members_on_artist_id_and_position"
    t.index ["artist_id"], name: "index_artist_members_on_artist_id"
  end

  create_table "artist_social_links", force: :cascade do |t|
    t.integer "artist_id", null: false
    t.datetime "created_at", null: false
    t.string "label", default: "", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["artist_id", "position"], name: "index_artist_social_links_on_artist_id_and_position"
    t.index ["artist_id"], name: "index_artist_social_links_on_artist_id"
  end

  create_table "artists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "genre"
    t.integer "kind", default: 0, null: false
    t.string "name", null: false
    t.string "official_link"
    t.boolean "published", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_artists_on_name", unique: true
  end

  create_table "discounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "kind", null: false
    t.string "name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 0, null: false
    t.index ["name"], name: "index_discounts_on_name", unique: true
    t.index ["priority"], name: "index_discounts_on_priority"
  end

  create_table "evaluation_memos", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.json "data", default: {}, null: false
    t.integer "event_id"
    t.text "note", null: false
    t.integer "source_row"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_evaluation_memos_on_category"
    t.index ["event_id"], name: "index_evaluation_memos_on_event_id"
  end

  create_table "event_discounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "discount_id", null: false
    t.integer "event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["discount_id"], name: "index_event_discounts_on_discount_id"
    t.index ["event_id", "discount_id"], name: "index_event_discounts_on_event_id_and_discount_id", unique: true
    t.index ["event_id"], name: "index_event_discounts_on_event_id"
  end

  create_table "event_timetables", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.string "name"
    t.integer "position", default: 0, null: false
    t.string "stage_name", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "position"], name: "index_event_timetables_on_event_id_and_position"
    t.index ["event_id"], name: "index_event_timetables_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.time "door_time"
    t.integer "drink_fee", default: 0, null: false
    t.integer "entrance_fee", default: 0, null: false
    t.date "event_date", null: false
    t.integer "event_fee", default: 0, null: false
    t.string "name", null: false
    t.integer "organizer_id", null: false
    t.time "start_time"
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "venue", null: false
    t.index ["organizer_id"], name: "index_events_on_organizer_id"
    t.check_constraint "(event_fee + drink_fee) <= 100000", name: "check_events_fee_total_range"
    t.check_constraint "drink_fee >= 0 AND drink_fee <= 50000", name: "check_events_drink_fee_range"
    t.check_constraint "entrance_fee >= 0 AND entrance_fee <= 100000", name: "check_events_entrance_fee_range"
    t.check_constraint "event_fee >= 0 AND event_fee <= 50000", name: "check_events_event_fee_range"
  end

  create_table "timetable_slots", force: :cascade do |t|
    t.integer "artist_id", null: false
    t.boolean "changeover", default: false, null: false
    t.datetime "created_at", null: false
    t.time "end_time", null: false
    t.integer "event_id", null: false
    t.integer "event_timetable_id", null: false
    t.integer "position"
    t.string "stage_name"
    t.time "start_time", null: false
    t.datetime "updated_at", null: false
    t.index ["artist_id"], name: "index_timetable_slots_on_artist_id"
    t.index ["event_id", "start_time"], name: "index_timetable_slots_on_event_id_and_start_time"
    t.index ["event_id"], name: "index_timetable_slots_on_event_id"
    t.index ["event_timetable_id"], name: "index_timetable_slots_on_event_timetable_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "artist_members", "artists"
  add_foreign_key "artist_social_links", "artists"
  add_foreign_key "evaluation_memos", "events"
  add_foreign_key "event_discounts", "discounts"
  add_foreign_key "event_discounts", "events"
  add_foreign_key "event_timetables", "events"
  add_foreign_key "events", "users", column: "organizer_id"
  add_foreign_key "timetable_slots", "artists"
  add_foreign_key "timetable_slots", "event_timetables"
  add_foreign_key "timetable_slots", "events"
end
