class EventTimetable < ApplicationRecord
  belongs_to :event, inverse_of: :event_timetables
  has_many :timetable_slots, -> { order(:position, :start_time) }, dependent: :destroy, inverse_of: :event_timetable

  accepts_nested_attributes_for :timetable_slots, allow_destroy: true

  validates :stage_name, presence: true, length: { maximum: 100 }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  before_validation :assign_position
  before_validation :copy_stage_name_to_name

  scope :ordered, -> { order(:position, :id) }

  private

  def assign_position
    return if position.present?
    self.position = event&.event_timetables&.size.to_i
  end

  def copy_stage_name_to_name
    self.name = stage_name if name.blank? && stage_name.present?
  end
end
