class Event < ApplicationRecord
  enum :state, { draft: 0, published: 1 }, default: :draft

  belongs_to :organizer, class_name: "User"
  has_many :event_timetables, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :event
  has_many :timetable_slots, through: :event_timetables
  has_many :artists, through: :timetable_slots
  has_many :event_discounts, dependent: :destroy
  has_many :discounts, through: :event_discounts

  accepts_nested_attributes_for :event_timetables, allow_destroy: true

  validates :name, :event_date, :venue, presence: true
  validates :event_fee, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 50_000 }
  validates :drink_fee, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 50_000 }
  validates :entrance_fee, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100_000 }
  validate :event_date_must_be_future
  validate :door_before_start
  validate :published_requirements
  validate :total_fee_within_limit

  before_validation :assign_total_entrance_fee

  scope :upcoming, -> { where("event_date >= ?", Date.current).order(:event_date) }

  def discounted_price
    discounts.ordered.reduce(entrance_fee) { |price, discount| discount.apply_to(price) }
  end

  def state_i18n
    I18n.t("activerecord.enums.event.state.#{state}", default: state.humanize)
  end

  private

  def event_date_must_be_future
    return if event_date.blank?
    return if event_date >= Date.current

    errors.add(:event_date, "は今日以降の日付を指定してください")
  end

  def door_before_start
    return if door_time.blank? || start_time.blank?
    return if door_time <= start_time

    errors.add(:start_time, "は開場時刻以降を指定してください")
  end

  def published_requirements
    return unless published?

    slots =
      event_timetables.reject(&:marked_for_destruction?).flat_map do |timetable|
        timetable.timetable_slots.reject(&:marked_for_destruction?)
      end
    errors.add(:timetable_slots, "が1枠以上必要です") if slots.empty?
  end

  def total_fee_within_limit
    return if event_fee.blank? || drink_fee.blank?

    total = event_fee.to_i + drink_fee.to_i
    errors.add(:base, "イベント料とドリンク料の合計は100,000円以内にしてください") if total > 100_000
  end

  def assign_total_entrance_fee
    return if event_fee.nil? && drink_fee.nil?

    self.event_fee ||= 0
    self.drink_fee ||= 0
    self.entrance_fee = event_fee + drink_fee
  end
end
