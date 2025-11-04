class Artist < ApplicationRecord
  enum :kind, {
    band: 0,
    dj: 1,
    unit: 2,
    solo: 3,
    duo: 4,
    ensemble: 5,
    other: 6
  }, default: :band

  has_many :timetable_slots, dependent: :restrict_with_exception
  has_many :events, through: :timetable_slots
  has_many :social_links, -> { ordered }, class_name: "ArtistSocialLink", dependent: :destroy, inverse_of: :artist
  has_many :members, -> { ordered }, class_name: "ArtistMember", dependent: :destroy, inverse_of: :artist

  validates :name, presence: true, length: { maximum: 100 }, uniqueness: true
  validates :official_link, length: { maximum: 255 }, allow_blank: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  accepts_nested_attributes_for :social_links, allow_destroy: true
  accepts_nested_attributes_for :members, allow_destroy: true

  scope :published, -> { where(published: true) }

  def kind_i18n
    I18n.t("activerecord.enums.artist.kind.#{kind}", default: kind.humanize)
  end

  def self.human_enum_name(enum_name, value)
    I18n.t("activerecord.enums.artist.#{enum_name}.#{value}", default: value.to_s.humanize)
  end
end
