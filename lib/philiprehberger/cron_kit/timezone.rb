# frozen_string_literal: true

module Philiprehberger
  module CronKit
    # Converts timezone identifiers to UTC offsets using only stdlib.
    #
    # Supports: "UTC", fixed offsets ("+05:00", "-04:00"), and common POSIX
    # timezone names (e.g., "US/Eastern", "Europe/London") via ENV["TZ"].
    module Timezone
      # Resolve a timezone identifier to a UTC offset in seconds.
      def self.utc_offset_for(timezone)
        return nil if timezone.nil?

        try_utc(timezone) || try_numeric_offset(timezone) || probe_offset(timezone)
      end

      # Convert a Time to the equivalent moment in the given timezone offset (seconds).
      def self.apply(time, offset_seconds)
        Time.new(time.year, time.month, time.day, time.hour, time.min, time.sec, offset_seconds)
      end

      class << self
        private

        def try_utc(timezone)
          return 0 if timezone.upcase == "UTC"
        end

        def try_numeric_offset(timezone)
          m = timezone.match(/\A([+-])(\d{1,2}):(\d{2})\z/)
          return unless m

          sign = m[1] == "+" ? 1 : -1
          sign * (m[2].to_i * 3600 + m[3].to_i * 60)
        end

        def probe_offset(timezone)
          original_tz = ENV.fetch("TZ", nil)
          ENV["TZ"] = timezone
          offset = Time.now.utc_offset
          offset
        ensure
          restore_tz(original_tz)
        end

        def restore_tz(original_tz)
          if original_tz
            ENV["TZ"] = original_tz
          else
            ENV.delete("TZ")
          end
        end
      end
    end
  end
end
