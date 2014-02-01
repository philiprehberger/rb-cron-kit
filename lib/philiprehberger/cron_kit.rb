# frozen_string_literal: true

require_relative "cron_kit/version"
require_relative "cron_kit/expression"
require_relative "cron_kit/scheduler"

module Philiprehberger
  module CronKit
    # Parse a 5-field cron expression and return an Expression instance.
    def self.parse(expression)
      Expression.new(expression)
    end

    # Create a new Scheduler instance.
    def self.new
      Scheduler.new
    end
  end
end
