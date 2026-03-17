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

      def parse_expression(expression)
        parts = expression.split(/\s+/)

        raise ParseError, "expected 5 fields, got #{parts.length}: #{expression.inspect}" unless parts.length == 5

        parts.each_with_index.map do |part, index|
          parse_field(part, FIELD_RANGES[index], FIELD_NAMES[index])
        end
      end

      private

      def parse_field(field, range, name)
        values = field.split(",").flat_map { |token| parse_token(token, range, name) }
        raise ParseError, "empty field for #{name}" if values.empty?

        values.uniq.sort
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
        return unless token == "*"

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
