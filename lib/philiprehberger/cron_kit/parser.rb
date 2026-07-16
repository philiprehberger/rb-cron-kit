# frozen_string_literal: true

module Philiprehberger
  module CronKit
    # Parsing logic for 5-field cron expressions.
    # Extracted from Expression to keep class size manageable.
    module Parser
      FIELD_RANGES = [
        0..59,  # minute
        0..23,  # hour
        1..31,  # day of month
        1..12,  # month
        0..6    # day of week
      ].freeze

      FIELD_NAMES = %w[minute hour day-of-month month day-of-week].freeze

      # Three-letter month names (case-insensitive) mapped to their numeric value.
      MONTH_NAMES = {
        'JAN' => 1, 'FEB' => 2, 'MAR' => 3, 'APR' => 4, 'MAY' => 5, 'JUN' => 6,
        'JUL' => 7, 'AUG' => 8, 'SEP' => 9, 'OCT' => 10, 'NOV' => 11, 'DEC' => 12
      }.freeze

      # Three-letter weekday names (case-insensitive) mapped to their numeric value.
      DAY_NAMES = {
        'SUN' => 0, 'MON' => 1, 'TUE' => 2, 'WED' => 3, 'THU' => 4, 'FRI' => 5, 'SAT' => 6
      }.freeze

      # Sunday may be written as 7 in the day-of-week field (Vixie cron interop).
      DOW_SUNDAY_ALIAS = 7

      def parse_expression(expression)
        parts = expression.split(/\s+/)

        raise ParseError, "expected 5 fields, got #{parts.length}: #{expression.inspect}" unless parts.length == 5

        parts.each_with_index.map do |part, index|
          parse_field(part, FIELD_RANGES[index], FIELD_NAMES[index])
        end
      end

      private

      def parse_field(field, range, name)
        normalized = normalize_names(field, name)
        parse_range = parse_range_for(name, range)
        values = normalized.split(',').flat_map { |token| parse_token(token, parse_range, name) }
        raise ParseError, "empty field for #{name}" if values.empty?

        values = values.map { |value| value == DOW_SUNDAY_ALIAS ? 0 : value } if name == 'day-of-week'
        values.uniq.sort
      end

      # Replace three-letter month/weekday names (case-insensitive) with their
      # numeric value before numeric parsing. Names are supported in single
      # values, lists, and ranges (e.g. MON-FRI, JAN,JUN,DEC).
      def normalize_names(field, name)
        table = name_table_for(name)
        return field unless table

        field.gsub(/[A-Za-z]+/) do |word|
          table.fetch(word.upcase) do
            raise ParseError, "invalid name #{word.inspect} in #{name} field"
          end
        end
      end

      def name_table_for(name)
        case name
        when 'month' then MONTH_NAMES
        when 'day-of-week' then DAY_NAMES
        end
      end

      # The day-of-week field accepts 7 as an alias for Sunday, so parsing must
      # tolerate 7 (mapped to 0 afterwards) even though the field range is 0..6.
      def parse_range_for(name, range)
        name == 'day-of-week' ? (range.min..DOW_SUNDAY_ALIAS) : range
      end

      def parse_token(token, range, name)
        try_wildcard(token, range) ||
          try_step(token, range, name) ||
          try_range_step(token, range, name) ||
          try_range(token, range, name) ||
          try_value(token, range, name) ||
          raise(ParseError, "invalid token #{token.inspect} in #{name} field")
      end

      def try_wildcard(token, range)
        return unless token == '*'

        range.to_a
      end

      def try_step(token, range, name)
        m = token.match(%r{\A\*/(\d+)\z})
        return unless m

        step = m[1].to_i
        validate_step!(step, name)
        range.step(step).to_a
      end

      def try_range_step(token, range, name)
        m = token.match(%r{\A(\d+)-(\d+)/(\d+)\z})
        return unless m

        build_range_step(m, range, name)
      end

      def build_range_step(match, range, name)
        low = match[1].to_i
        high = match[2].to_i
        step = match[3].to_i
        validate_range!(low, high, range, name)
        validate_step!(step, name)
        (low..high).step(step).to_a
      end

      def try_range(token, range, name)
        m = token.match(/\A(\d+)-(\d+)\z/)
        return unless m

        low = m[1].to_i
        high = m[2].to_i
        validate_range!(low, high, range, name)
        (low..high).to_a
      end

      def try_value(token, range, name)
        return unless token.match?(/\A\d+\z/)

        value = token.to_i
        validate_value!(value, range, name)
        [value]
      end

      def validate_value!(value, range, name)
        return if range.include?(value)

        raise ParseError, "#{name} value #{value} outside allowed range #{range}"
      end

      def validate_range!(low, high, range, name)
        raise ParseError, "invalid range #{low}-#{high} in #{name} field: low > high" if low > high

        validate_value!(low, range, name)
        validate_value!(high, range, name)
      end

      def validate_step!(step, name)
        raise ParseError, "step must be > 0 in #{name} field" if step <= 0
      end
    end
  end
end
