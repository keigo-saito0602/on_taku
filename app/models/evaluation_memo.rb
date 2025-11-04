require "csv"

class EvaluationMemo < ApplicationRecord
  belongs_to :event, optional: true

  validates :category, presence: true, length: { maximum: 255 }
  validates :note, presence: true

  def self.import_from_csv(io, event: nil)
    created = []
    raw = io.respond_to?(:read) ? io.read : io.to_s
    csv_rows = CSV.parse(raw, headers: true)
    headers = csv_rows.headers.compact
    raise CSV::MalformedCSVError.new("CSVにヘッダー行がありません", nil) if headers.empty?
    required_headers = ["実績/補足"]
    unless (headers & required_headers).any?
      raise CSV::MalformedCSVError.new("必須ヘッダー(#{required_headers.join(', ')})が見つかりません", nil)
    end
    csv_rows.each_with_index do |row, index|
      category = row["大項目"].presence || row["中項目"].presence || row["小項目"].presence || "未分類"
      note = row["実績/補足"].presence || row.fields.compact.join("\n").presence || category
      data_hash = row.to_h.compact

      created << create!(
        event: event,
        category:,
        note:,
        source_row: index + 2, # header assumed line 1
        data: data_hash
      )
    end
    created
  end
end
