class ArtistSocialLink < ApplicationRecord
  URL_REGEXP = URI::DEFAULT_PARSER.make_regexp(%w[http https])

  belongs_to :artist, inverse_of: :social_links

  validates :label, length: { maximum: 50 }, allow_blank: true
  validates :url, presence: true, length: { maximum: 255 }, format: { with: URL_REGEXP }, unless: :marked_for_destruction?
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  before_validation :mark_blank_for_removal
  before_validation :assign_position

  scope :ordered, -> { order(:position, :id) }

  private

  def mark_blank_for_removal
    mark_for_destruction if url.blank?
  end

  def assign_position
    return if marked_for_destruction?
    return if position.present?

    self.position = artist&.social_links&.size.to_i
  end
end
