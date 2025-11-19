class Discount < ApplicationRecord
  KINDS = {
    percentage: "percentage",
    fixed: "fixed",
    perk: "perk",
    other: "other"
  }.freeze

  CATEGORY_LABELS = {
    "set" => "セット割",
    "student" => "学割",
    "staff" => "スタッフ割",
    "early" => "早割",
    "custom" => "その他"
  }.freeze

  SCOPE_LABELS = {
    "total" => "合計全体",
    "ticket" => "チケット",
    "drink" => "ドリンク",
    "merch" => "物販"
  }.freeze

  STACKING_LABELS = {
    "stackable" => "併用可",
    "same_scope" => "同一範囲排他",
    "exclusive" => "完全排他"
  }.freeze

  CATEGORIES =
    CATEGORY_LABELS.keys.each_with_object({}) do |key, hash|
      hash[key.to_sym] = key
    end.freeze
  SCOPES =
    SCOPE_LABELS.keys.each_with_object({}) do |key, hash|
      hash[key.to_sym] = key
    end.freeze
  STACKING_RULES =
    STACKING_LABELS.keys.each_with_object({}) do |key, hash|
      hash[key.to_sym] = key
    end.freeze

  enum :kind, KINDS, prefix: true
  enum :category, CATEGORIES, prefix: true
  enum :scope, SCOPES, prefix: true
  enum :stacking_rule, STACKING_RULES

  has_many :event_discounts, dependent: :destroy
  has_many :events, through: :event_discounts

  validates :name, presence: true, uniqueness: true
  validates :kind, :category, :scope, :stacking_rule, presence: true
  validates :value,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: ->(discount) { discount.kind_percentage? ? 100 : 50_000 }
    }
  validates :priority, numericality: { greater_than_or_equal_to: 0 }
  validates :minimum_amount,
    :minimum_quantity,
    :usage_limit_per_user,
    :usage_limit_total,
    numericality: { greater_than_or_equal_to: 0 }
  validate :start_at_before_end_at

  scope :ordered, -> { order(:priority, :name) }
  scope :published, -> { where(published: true) }
  scope :active_at,
    lambda { |time|
      where("start_at IS NULL OR start_at <= ?", time)
        .where("end_at IS NULL OR end_at >= ?", time)
    }
  scope :available_for,
    lambda { |time = Time.current|
      published.active_at(time)
    }

  def status(time = Time.current)
    return :unpublished unless published?
    return :upcoming if start_at.present? && time < start_at
    return :expired if end_at.present? && time > end_at

    :active
  end

  def status_label(time = Time.current)
    {
      active: "利用可能",
      upcoming: "開始前",
      expired: "期限切れ",
      unpublished: "未公開"
    }[status(time)]
  end

  def available?(time = Time.current)
    status(time) == :active
  end

  def scope_label
    self.class.scope_label_for(scope)
  end

  def stacking_label
    self.class.stacking_label_for(stacking_rule)
  end

  def category_label
    self.class.category_label_for(category)
  end

  def self.scope_label_for(value)
    SCOPE_LABELS[value.to_s]
  end

  def self.stacking_label_for(value)
    STACKING_LABELS[value.to_s]
  end

  def self.category_label_for(value)
    CATEGORY_LABELS[value.to_s]
  end

  private

  def start_at_before_end_at
    return if start_at.blank? || end_at.blank?
    return if start_at <= end_at

    errors.add(:end_at, "は開始日時以降を指定してください")
  end
end
