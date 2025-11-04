class TimetableSlot < ApplicationRecord
  SLOT_INCREMENT_MINUTES = 5
  PERFORMANCE_TEMPLATES = [20, 30, 45, 60, 90].freeze
  CHANGEOVER_TEMPLATES = [5, 10, 15].freeze

  belongs_to :event
  belongs_to :event_timetable, inverse_of: :timetable_slots
  belongs_to :artist, optional: true

  validates :start_time, :end_time, presence: true
  validate :end_after_start
  validate :time_on_grid
  validate :slot_in_increment
  validate :no_overlap
  validates :artist, presence: true, unless: :allow_blank_artist?

  before_validation :ensure_position
  before_validation :sync_event_with_timetable

  private

  def end_after_start
    return if start_time.blank? || end_time.blank?
    return if start_time < end_time

    errors.add(:end_time, "は開始時刻より後を指定してください")
  end

  def slot_in_increment
    return if start_time.blank? || end_time.blank?

    length = minutes_since_midnight(end_time) - minutes_since_midnight(start_time)
    return if length.positive? && (length % SLOT_INCREMENT_MINUTES).zero?

    errors.add(:base, "枠の長さは#{SLOT_INCREMENT_MINUTES}分単位で設定してください")
  end

  def no_overlap
    return if event.blank? || start_time.blank? || end_time.blank?

    timetable = event_timetable || event&.event_timetables&.first
    return if timetable.blank?

    conflict = timetable.timetable_slots.reject do |slot|
      slot == self || slot.marked_for_destruction?
    end.find do |slot|
      slot_start = slot.start_time
      slot_end = slot.end_time
      (start_time < slot_end) && (end_time > slot_start)
    end

    errors.add(:base, "他の枠と時刻が重複しています") if conflict
  end

  def minutes_since_midnight(time_value)
    time_value.seconds_since_midnight.to_i / 60
  end

  def time_on_grid
    return if start_time.blank? || end_time.blank?

    unless on_grid?(start_time) && on_grid?(end_time)
      errors.add(:base, "#{SLOT_INCREMENT_MINUTES}分刻みの時刻を選択してください")
    end
  end

  def on_grid?(time_value)
    minutes_since_midnight(time_value) % SLOT_INCREMENT_MINUTES == 0
  end

  def ensure_position
    return if position.present?

    siblings =
      if event_timetable
        event_timetable.timetable_slots
      else
        event&.timetable_slots || []
      end
    self.position = siblings.count + 1
  end

  def allow_blank_artist?
    changeover? || other_slot?
  end

  def other_slot?
    changeover? == false && artist_id.blank? && stage_name.present?
  end

  def sync_event_with_timetable
    return if event_timetable.blank?

    self.event_id = event_timetable.event_id
    self.stage_name = event_timetable.stage_name if event_timetable.stage_name.present?
  end
end
