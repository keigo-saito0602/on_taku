class ArtistMember < ApplicationRecord
  belongs_to :artist, inverse_of: :members

  validates :name, presence: true, length: { maximum: 100 }, unless: :marked_for_destruction?
  validates :instrument, length: { maximum: 100 }, allow_blank: true
  validates :role, length: { maximum: 100 }, allow_blank: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  before_validation :mark_blank_for_removal
  before_validation :assign_position

  scope :ordered, -> { order(:position, :id) }

  private

  def mark_blank_for_removal
    mark_for_destruction if name.blank?
  end

  def assign_position
    return if marked_for_destruction?
    return if position.present?

    self.position = artist&.members&.size.to_i
  end
end
