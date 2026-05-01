# frozen_string_literal: true

module Philiprehberger
  module CronKit
    # A simple in-process cron scheduler that checks registered jobs every 60 seconds.
    class Scheduler
      include TimeoutHandler

      Job = Struct.new(:expression, :block, :name, :timeout, :overlap, keyword_init: true)

      def initialize
        @jobs = []
        @mutex = Mutex.new
        @thread = nil
        @running = false
        @on_error = nil
        @running_threads = []
        @job_threads = {}
      end

      def on_error(&block)
        return @on_error unless block

        @on_error = block
      end

      def running_jobs
        @mutex.synchronize { @running_threads.count(&:alive?) }
      end

      def every(expression, name: nil, timeout: nil, overlap: true, &block)
        expr = expression.is_a?(Expression) ? expression : Expression.new(expression)

        @mutex.synchronize do
          @jobs << Job.new(expression: expr, block: block, name: name, timeout: timeout, overlap: overlap)
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

      # Manually trigger a registered job by name.
      #
      # Reuses the standard execution path (timeout + overlap-skip), but runs
      # synchronously so the caller can capture the return value. Useful for
      # testing and operator-driven re-runs.
      #
      # @param name [Symbol, String] the job name to trigger
      # @return [Object, nil] the block's return value, or `nil` when skipped due to `overlap: false`
      # @raise [KeyError] if no job is registered under `name`
      # @raise [Timeout::Error] if the job's `timeout:` is exceeded
      def run_now(name)
        job = @mutex.synchronize { @jobs.find { |j| j.name == name } }
        raise KeyError, "job not registered: #{name.inspect}" unless job
        return nil if skip_overlapping?(job)

        execute_now(job)
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
          next if skip_overlapping?(job)

          thread = start_job_thread(job, now)
          @mutex.synchronize do
            @running_threads << thread
            @job_threads[job.object_id] = thread
          end
          thread
        end

        threads.each { |t| t.join(30) }
        @mutex.synchronize do
          @running_threads.select!(&:alive?)
          @job_threads.select! { |_, t| t.alive? }
        end
      end

      def skip_overlapping?(job)
        return false if job.overlap

        @mutex.synchronize do
          thread = @job_threads[job.object_id]
          thread&.alive? || false
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

      def execute_now(job)
        result = nil
        error = nil

        worker = Thread.new do
          result = job.block.call(Time.now)
        rescue StandardError => e
          error = e
        end

        @mutex.synchronize do
          @running_threads << worker
          @job_threads[job.object_id] = worker
        end

        begin
          if job.timeout && !worker.join(job.timeout)
            worker.raise(Timeout::Error, 'job exceeded timeout')
            worker.join(1)
            worker.kill if worker.alive?
            raise Timeout::Error, "job #{job.name.inspect} exceeded timeout of #{job.timeout}s"
          end

          worker.join unless job.timeout
          raise error if error

          result
        ensure
          @mutex.synchronize do
            @running_threads.delete(worker)
            @job_threads.delete(job.object_id) if @job_threads[job.object_id] == worker
          end
        end
      end
    end
  end
end
