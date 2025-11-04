class User < ApplicationRecord
  has_secure_password

  enum :role, { organizer: 0, reviewer: 1 }, default: :organizer

  has_many :events, foreign_key: :organizer_id, inverse_of: :organizer, dependent: :destroy

  validates :name, :display_name, :email, presence: true
  validates :email, uniqueness: true, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8, maximum: 32 }, allow_nil: true

  def role_i18n
    I18n.t("activerecord.enums.user.role.#{role}", default: role.humanize)
  end
end
