# frozen_string_literal: true

module Philiprehberger
  module CronKit
    # Maps non-standard cron aliases to their 5-field equivalents.
    module Aliases
      MAPPINGS = {
        "@yearly" => "0 0 1 1 *",
        "@annually" => "0 0 1 1 *",
        "@monthly" => "0 0 1 * *",
        "@weekly" => "0 0 * * 0",
        "@daily" => "0 0 * * *",
        "@hourly" => "0 * * * *"
      }.freeze

      # Expand an alias to its 5-field cron expression, or return the input unchanged.
      def self.expand(expression)
        MAPPINGS.fetch(expression.strip.downcase, expression)
      end
    end
  end
end
