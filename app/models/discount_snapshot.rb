class DiscountSnapshot < ApplicationRecord
  belongs_to :event

  validates :total_before,
    :total_after,
    :ticket_before,
    :ticket_after,
    :drink_before,
    :drink_after,
    :merch_before,
    :merch_after,
    numericality: { greater_than_or_equal_to: 0 }
  validates :rounding_mode, inclusion: { in: %w[floor ceil round] }

  def summary
    {
      total_before:,
      total_after:,
      applied_count: applied_discounts.size
    }
  end
end
