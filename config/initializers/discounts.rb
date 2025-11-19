Rails.application.config.x.discounts = ActiveSupport::OrderedOptions.new unless Rails.application.config.x.respond_to?(:discounts)

rounding_mode =
  ENV.fetch("DISCOUNT_ROUNDING_MODE", "floor").to_s.downcase

Rails.application.config.x.discounts.rounding_mode =
  if %w[floor ceil round].include?(rounding_mode)
    rounding_mode.to_sym
  else
    :floor
  end
