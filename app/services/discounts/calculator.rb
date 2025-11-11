require "set"

module Discounts
  class Calculator
    Result = Struct.new(
      :total_before,
      :total_after,
      :ticket_before,
      :ticket_after,
      :drink_before,
      :drink_after,
      :merch_before,
      :merch_after,
      :rounding_mode,
      :applied_discounts,
      keyword_init: true
    ) do
      def savings
        total_before - total_after
      end

      def as_json(*)
        {
          total_before:,
          total_after:,
          savings:,
          ticket_before:,
          ticket_after:,
          drink_before:,
          drink_after:,
          merch_before:,
          merch_after:,
          rounding_mode:,
          applied_discounts:
        }
      end
    end

    CATEGORY_SEQUENCE = %w[set student staff early].freeze

    class State
      attr_reader :amounts, :applied_discounts, :rounding_mode, :applied_scopes

      def initialize(amounts:, rounding_mode:)
        @amounts = amounts.transform_values(&:to_i)
        @rounding_mode = rounding_mode
        @applied_discounts = []
        @applied_scopes = Hash.new(0)
      end

      def dup
        self.class.new(amounts: amounts.dup, rounding_mode:).tap do |state|
          state.applied_discounts.concat(applied_discounts.map(&:dup))
          state.applied_scopes.merge!(applied_scopes)
        end
      end

      def replace!(other)
        @amounts = other.amounts.dup
        @applied_discounts = other.applied_discounts.map(&:dup)
        @applied_scopes = other.applied_scopes.dup
      end

      def total
        amounts.values.sum
      end

      def record(discount, detail)
        @applied_discounts << detail.merge(
          id: discount.id,
          name: discount.name,
          scope: discount.scope,
          category: discount.category,
          kind: discount.kind,
          value: discount.value,
          stacking_rule: discount.stacking_rule,
          priority: discount.priority
        )
        @applied_scopes[discount.scope] += 1
      end
    end

    attr_reader :event, :context, :rounding_mode

    def initialize(event:, discounts: nil, context: {})
      @event = event
      @context = context
      @reference_time = context[:reference_time] || Time.current
      @rounding_mode = (Rails.configuration.x.discounts.rounding_mode || :floor).to_sym
      @all_discounts = (discounts || event.discounts).ordered
      @state = State.new(amounts: initial_amounts.slice(:ticket, :drink, :merch), rounding_mode:)
      @handled_categories = Set.new
    end

    def result
      return @result if defined?(@result)

      apply_category("set")
      apply_student_vs_staff
      apply_category("early")
      apply_remaining_categories

      @result =
        Result.new(
          total_before: initial_amounts.values.sum,
          total_after: @state.total,
          ticket_before: initial_amounts[:ticket],
          ticket_after: @state.amounts[:ticket],
          drink_before: initial_amounts[:drink],
          drink_after: @state.amounts[:drink],
          merch_before: initial_amounts[:merch],
          merch_after: @state.amounts[:merch],
          rounding_mode:,
          applied_discounts: @state.applied_discounts
        )
    end

    private

    def initial_amounts
      @initial_amounts ||= {
        ticket: event.ticket_subtotal,
        drink: event.drink_subtotal,
        merch: context.fetch(:merch_total, 0).to_i
      }
    end

    def eligible_discounts
      @eligible_discounts ||= @all_discounts.select { |discount| discount.available?(@reference_time) }
    end

    def discounts_for_category(category)
      eligible_discounts.select { |discount| discount.category == category }
    end

    def apply_category(category)
      @handled_categories << category
      apply_group(discounts_for_category(category))
    end

    def apply_remaining_categories
      remaining =
        eligible_discounts.reject { |discount| @handled_categories.include?(discount.category) }
      return if remaining.empty?

      grouped = remaining.group_by(&:category)
      grouped.keys.sort.each do |category|
        apply_group(grouped[category])
      end
    end

    def apply_student_vs_staff
      @handled_categories.merge(%w[student staff])
      student_discounts = discounts_for_category("student")
      staff_discounts = discounts_for_category("staff")

      if student_discounts.any? && staff_discounts.any?
        state_a = simulate_group(student_discounts)
        state_b = simulate_group(staff_discounts)
        chosen = pick_better_state(state_a, state_b)
        @state.replace!(chosen)
      else
        apply_group(student_discounts + staff_discounts)
      end
    end

    def simulate_group(discounts)
      state = @state.dup
      apply_group(discounts, state:)
      state
    end

    def pick_better_state(state_a, state_b)
      savings_a = @state.total - state_a.total
      savings_b = @state.total - state_b.total
      return state_a if savings_a > savings_b
      return state_b if savings_b > savings_a

      priority_a = lowest_priority(state_a)
      priority_b = lowest_priority(state_b)
      return state_a if priority_a <= priority_b

      state_b
    end

    def lowest_priority(state)
      state.applied_discounts.map { |row| row[:priority] }.min || Float::INFINITY
    end

    def apply_group(discounts, state: @state)
      return if discounts.blank?

      ordered =
        discounts.sort_by do |discount|
          [
            discount.kind_percentage? ? 0 : (discount.kind_fixed? ? 1 : 2),
            discount.priority,
            discount.id
          ]
        end

      ordered.each do |discount|
        apply_discount(discount, state:)
      end
    end

    def apply_discount(discount, state: @state)
      return unless meets_requirements?(discount, state)

      base_amount = base_amount_for(discount, state)
      return if base_amount <= 0

      savings = calculate_savings(discount, base_amount)
      updated_amounts = distribute_savings(discount, state, savings, base_amount)

      detail = {
        amount_before: base_amount,
        amount_after: updated_amounts.fetch(:after),
        savings:
      }

      detail[:line_breakdown] = updated_amounts[:breakdown] if updated_amounts[:breakdown].present?

      state.record(discount, detail)
    end

    def meets_requirements?(discount, state)
      return false if discount.minimum_amount.positive? && base_amount_for(discount, state) < discount.minimum_amount
      return false if discount.minimum_quantity.positive? && quantity_for(discount) < discount.minimum_quantity

      if discount.stacking_rule == "exclusive" && state.applied_discounts.any?
        return false
      end

      if discount.stacking_rule == "same_scope" && state.applied_scopes[discount.scope].positive?
        return false
      end

      true
    end

    def quantity_for(discount)
      case discount.scope
      when "ticket"
        context.fetch(:ticket_quantity, 0).to_i
      when "drink"
        context.fetch(:drink_quantity, 0).to_i
      when "merch"
        context.fetch(:merch_quantity, 0).to_i
      else
        context.fetch(:total_quantity, 0).to_i
      end
    end

    def base_amount_for(discount, state)
      case discount.scope
      when "ticket"
        state.amounts[:ticket]
      when "drink"
        state.amounts[:drink]
      when "merch"
        state.amounts[:merch]
      else
        state.total
      end
    end

    def calculate_savings(discount, base_amount)
      if discount.kind_percentage?
        after = round(base_amount * (100 - discount.value) / 100.0)
        (base_amount - after).clamp(0, base_amount)
      elsif discount.kind_fixed?
        [ discount.value, base_amount ].min
      else
        0
      end
    end

    def distribute_savings(discount, state, savings, base_amount)
      after = base_amount - savings

      case discount.scope
      when "ticket"
        state.amounts[:ticket] = after
        { after: state.amounts[:ticket] }
      when "drink"
        state.amounts[:drink] = after
        { after: state.amounts[:drink] }
      when "merch"
        state.amounts[:merch] = after
        { after: state.amounts[:merch] }
      else
        breakdown = allocate_total_savings(state, savings)
        { after: state.total, breakdown: }
      end
    end

    def allocate_total_savings(state, savings)
      return {} if savings.zero?

      total_before = state.total
      return {} if total_before.zero?

      remaining = savings
      breakdown = {}

      %i[ticket drink merch].each_with_index do |key, index|
        amount = state.amounts[key]
        next if amount.zero?

        share =
          if index == 2
            remaining
          else
            round(savings * amount / total_before.to_f).clamp(0, remaining)
          end

        state.amounts[key] = [ amount - share, 0 ].max
        breakdown[key] = share
        remaining -= share
      end

      breakdown
    end

    def round(value)
      case rounding_mode
      when :ceil
        value.ceil
      when :round
        value.round
      else
        value.floor
      end
    end
  end
end
