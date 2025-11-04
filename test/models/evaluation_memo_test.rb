require "test_helper"
require "csv"
require "stringio"

class EvaluationMemoTest < ActiveSupport::TestCase
  setup do
    @organizer = User.create!(
      name: "評価者",
      display_name: "Reviewer",
      email: "reviewer@example.com",
      password: "Password1",
      password_confirmation: "Password1"
    )
    @event = @organizer.events.create!(name: "イベント", event_date: Date.current + 1, venue: "Club", event_fee: 800, drink_fee: 200)
  end

  test "imports csv rows" do
    csv = <<~CSV
      大項目,中項目,小項目,レベル1,習得済,実績/補足
      品質,テスト設計,,〇,\"\",ディシジョンテーブルを適用
    CSV

    memos = EvaluationMemo.import_from_csv(StringIO.new(csv), event: @event)
    assert_equal 1, memos.size
    memo = memos.first
    assert_equal "品質", memo.category
    assert_equal @event, memo.event
    assert_match "ディシジョンテーブル", memo.note
  end

  test "raises error when header missing" do
    csv = <<~CSV
      1,2,3
      a,b,c
    CSV

    assert_raises CSV::MalformedCSVError do
      EvaluationMemo.import_from_csv(StringIO.new(csv), event: @event)
    end
  end
end
