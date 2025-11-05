require "uri"

module ApplicationHelper
  def display_currency(amount)
    amount.to_i.zero? ? "無料" : "¥#{number_with_delimiter(amount)}"
  end

  def safe_external_url(raw_url)
    return nil if raw_url.blank?

    uri = URI.parse(raw_url)
    return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
