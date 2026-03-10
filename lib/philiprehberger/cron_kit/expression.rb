# frozen_string_literal: true

module Philiprehberger
  module CronKit
    class ParseError < StandardError; end

    # Parses and evaluates 5-field cron expressions.
    #
    # Supported fields: minute (0-59), hour (0-23), day-of-month (1-31),
    # month (1-12), day-of-week (0-6, Sunday = 0).
    #
    # Supported syntax: *, specific values, ranges (1-5), steps (*/5), lists (1,3,5).
    class Expression
      FIELD_RANGES = [
        0..59,  # minute
        0..23,  # hour
        1..31,  # day of month
        1..12,  # month
        0..6    # day of week
      ].freeze

      FIELD_NAMES = %w[minute hour day-of-month month day-of-week].freeze

      attr_reader :raw

      def initialize(expression)
        @raw = expression.to_s.strip
        @fields = parse(@raw)
      end

      def match?(time)
        time = time.to_time if time.respond_to?(:to_time)

        values = [time.min, time.hour, time.day, time.month, time.wday]
        @fields.each_with_index.all? { |set, i| set.include?(values[i]) }
      end

      def next_at(from: Time.now)
        time = Time.new(from.year, from.month, from.day, from.hour, from.min, 0, from.utc_offset)
        time += 60 # start from the next minute

        # Safety limit: scan up to 4 years of minutes
        (4 * 366 * 24 * 60).times do
          return time if match?(time)

          time += 60
        end

        raise "no matching time found within 4 years"
      end

      def to_s
        @raw
      end

      private

      def parse(expression)
        parts = expression.split(/\s+/)

        raise ParseError, "expected 5 fields, got #{parts.length}: #{expression.inspect}" unless parts.length == 5

        parts.each_with_index.map do |part, index|
          parse_field(part, FIELD_RANGES[index], FIELD_NAMES[index])
        end
      end

      def parse_field(field, range, name)
        values = field.split(",").flat_map { |token| parse_token(token, range, name) }
        raise ParseError, "empty field for #{name}" if values.empty?

        values.uniq.sort
      end

      def parse_token(token, range, name)
        case token
        when "*"
          range.to_a
        when %r{\A\*/(\d+)\z}
          parse_step_token(range, name)
        when /\A(\d+)-(\d+)\z/
          parse_range_token(range, name)
        when %r{\A(\d+)-(\d+)/(\d+)\z}
          parse_range_step_token(range, name)
        when /\A\d+\z/
          parse_value_token(token, range, name)
        else
          raise ParseError, "invalid token #{token.inspect} in #{name} field"
        end
      end

      def parse_step_token(range, name)
        step = Regexp.last_match(1).to_i
        validate_step!(step, name)
        range.step(step).to_a
      end

      def parse_range_token(range, name)
        low = Regexp.last_match(1).to_i
        high = Regexp.last_match(2).to_i
        validate_range!(low, high, range, name)
        (low..high).to_a
      end

      def parse_range_step_token(range, name)
        low = Regexp.last_match(1).to_i
        high = Regexp.last_match(2).to_i
        step = Regexp.last_match(3).to_i
        validate_range!(low, high, range, name)
        validate_step!(step, name)
        (low..high).step(step).to_a
      end

      def parse_value_token(token, range, name)
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
