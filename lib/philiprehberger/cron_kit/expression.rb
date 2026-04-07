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
    # Non-standard aliases: @hourly, @daily, @weekly, @monthly, @yearly, @annually.
    class Expression
      include Parser

      attr_reader :raw, :timezone

      # Return true if the given expression parses without error.
      # Provides a non-raising alternative to rescuing `ParseError`.
      def self.valid?(expression, timezone: nil)
        new(expression, timezone: timezone)
        true
      rescue ParseError, ArgumentError
        false
      end

      def initialize(expression, timezone: nil)
        @raw = Aliases.expand(expression.to_s.strip)
        @timezone = timezone
        @utc_offset = Timezone.utc_offset_for(timezone)
        @fields = parse_expression(@raw)
      end

      def match?(time)
        time = coerce_time(time)
        values = [time.min, time.hour, time.day, time.month, time.wday]
        @fields.each_with_index.all? { |set, i| set.include?(values[i]) }
      end

      def next_at(from: Time.now)
        time = start_time(from, 60)
        scan_forward(time)
      end

      def next_runs(count: 5, from: Time.now)
        result = []
        cursor = from
        count.times do
          cursor = next_at(from: cursor)
          result << cursor
        end
        result
      end

      def previous_run(from: Time.now)
        time = start_time_back(from)
        scan_backward(time)
      end

      def to_s
        @raw
      end

      private

      def coerce_time(time)
        time = time.to_time if time.respond_to?(:to_time)
        @utc_offset ? Timezone.apply(time.getutc + @utc_offset, @utc_offset) : time
      end

      def start_time(from, offset_seconds)
        base = @utc_offset ? from.getutc : from
        time = Time.new(base.year, base.month, base.day, base.hour, base.min, 0, base.utc_offset)
        time += offset_seconds
        @utc_offset ? Timezone.apply(time.getutc + @utc_offset, @utc_offset) : time
      end

      def start_time_back(from)
        base = @utc_offset ? from.getutc : from
        time = Time.new(base.year, base.month, base.day, base.hour, base.min, 0, base.utc_offset)
        time -= 60
        @utc_offset ? Timezone.apply(time.getutc + @utc_offset, @utc_offset) : time
      end

      def scan_forward(time)
        (4 * 366 * 24 * 60).times do
          return time if field_match?(time)

          time += 60
        end
        raise 'no matching time found within 4 years'
      end

      def scan_backward(time)
        (4 * 366 * 24 * 60).times do
          return time if field_match?(time)

          time -= 60
        end
        raise 'no matching time found within 4 years'
      end

      def field_match?(time)
        values = [time.min, time.hour, time.day, time.month, time.wday]
        @fields.each_with_index.all? { |set, i| set.include?(values[i]) }
      end
    end
  end
end
