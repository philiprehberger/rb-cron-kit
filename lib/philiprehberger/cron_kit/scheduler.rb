# frozen_string_literal: true

module Philiprehberger
  module CronKit
    # A simple in-process cron scheduler that checks registered jobs every 60 seconds.
    class Scheduler
      Job = Struct.new(:expression, :block, keyword_init: true)

      def initialize
        @jobs = []
        @mutex = Mutex.new
        @thread = nil
        @running = false
      end

      def every(expression, &block)
        expr = expression.is_a?(Expression) ? expression : Expression.new(expression)

        @mutex.synchronize do
          @jobs << Job.new(expression: expr, block: block)
        end

        self
      end

      def start
        @mutex.synchronize do
          return self if @running

          @running = true
        end

        @thread = Thread.new { run_loop }
        @thread.abort_on_exception = true

        self
      end

      def stop
        @mutex.synchronize { @running = false }
        @thread&.join(5)
        @thread = nil

        self
      end

      def running?
        @mutex.synchronize { @running }
      end

      private

      def run_loop
        while running?
          tick
          sleep_until_next_minute
        end
      end

      def tick
        now = Time.now
        jobs = @mutex.synchronize { @jobs.dup }

        jobs.each do |job|
          job.block.call(now) if job.expression.match?(now)
        end
      end

      def sleep_until_next_minute
        return unless running?

        remaining = 60 - Time.now.sec
        remaining.times do
          break unless running?

          sleep 1
        end
      end
    end
  end
end
