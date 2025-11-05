class Discount < ApplicationRecord
  enum :kind, { percentage: "percentage", fixed: "fixed" }, prefix: true

  has_many :event_discounts, dependent: :destroy
  has_many :events, through: :event_discounts

  validates :name, presence: true, uniqueness: true
  validates :kind, presence: true
  validates :value,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: ->(discount) { discount.kind_percentage? ? 100 : 50_000 }
    }
  validates :priority, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:priority, :name) }

  def apply_to(amount)
    return amount if amount.nil?

    case kind
    when "percentage"
      (amount * (100 - value) / 100.0).floor
    when "fixed"
      [ amount - value, 0 ].max
    else
      amount
    end
  end
end
