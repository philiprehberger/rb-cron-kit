# frozen_string_literal: true

require_relative 'cron_kit/version'
require_relative 'cron_kit/aliases'
require_relative 'cron_kit/timezone'
require_relative 'cron_kit/parser'
require_relative 'cron_kit/expression'
require_relative 'cron_kit/timeout_handler'
require_relative 'cron_kit/scheduler'

module Philiprehberger
  module CronKit
    # Parse a 5-field cron expression and return an Expression instance.
    # Supports non-standard aliases (@hourly, @daily, etc.) and optional timezone.
    def self.parse(expression, timezone: nil)
      Expression.new(expression, timezone: timezone)
    end

    # Create a new Scheduler instance.
    def self.new
      Scheduler.new
    end

    # Return true if the given string is a valid cron expression.
    # Accepts the same syntax as `parse` (5-field expressions and aliases).
    def self.valid?(expression, timezone: nil)
      Expression.valid?(expression, timezone: timezone)
    end
  end
end
