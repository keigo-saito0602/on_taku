class EventDiscount < ApplicationRecord
  belongs_to :event
  belongs_to :discount

  validates :discount_id, uniqueness: { scope: :event_id }
end
