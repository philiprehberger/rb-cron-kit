# frozen_string_literal: true

module Philiprehberger
  module CronKit
    # A simple in-process cron scheduler that checks registered jobs every 60 seconds.
    class Scheduler
      include TimeoutHandler

      Job = Struct.new(:expression, :block, :name, :timeout, keyword_init: true)

      def initialize
        @jobs = []
        @mutex = Mutex.new
        @thread = nil
        @running = false
        @on_error = nil
        @running_threads = []
      end

      def on_error(&block)
        return @on_error unless block

        @on_error = block
      end

      def running_jobs
        @mutex.synchronize { @running_threads.count(&:alive?) }
      end

      def every(expression, name: nil, timeout: nil, &block)
        expr = expression.is_a?(Expression) ? expression : Expression.new(expression)

        @mutex.synchronize do
          @jobs << Job.new(expression: expr, block: block, name: name, timeout: timeout)
        end

        self
      end

      def job_names
        @mutex.synchronize { @jobs.map(&:name).compact }
      end

      def remove(name)
        @mutex.synchronize do
          initial_size = @jobs.size
          @jobs.reject! { |job| job.name == name }
          @jobs.size < initial_size
        end
      end

      def next_runs(from: Time.now)
        jobs = @mutex.synchronize { @jobs.dup }

        jobs.each_with_object({}) do |job, hash|
          next unless job.name

          hash[job.name] = job.expression.next_at(from: from)
        end
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

        threads = jobs.filter_map do |job|
          next unless job.expression.match?(now)

          thread = start_job_thread(job, now)
          @mutex.synchronize { @running_threads << thread }
          thread
        end

        threads.each { |t| t.join(30) }
        @mutex.synchronize { @running_threads.select!(&:alive?) }
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
