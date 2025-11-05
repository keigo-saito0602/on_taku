module ApplicationHelper
  def display_currency(amount)
    amount.to_i.zero? ? "無料" : "¥#{number_with_delimiter(amount)}"
  end
end
