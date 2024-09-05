# frozen_string_literal: true

require 'timeout'

module Philiprehberger
  module CronKit
    # Handles job execution with optional timeout enforcement.
    module TimeoutHandler
      private

      def start_job_thread(job, now)
        Thread.new(job, now) do |j, t|
          run_with_timeout(j, t)
        rescue StandardError => e
          @on_error&.call(j, e)
        end
      end

      def run_with_timeout(job, time)
        return job.block.call(time) unless job.timeout

        execute_with_timeout(job, time)
      end

      def execute_with_timeout(job, time)
        worker = Thread.new { job.block.call(time) }
        return if worker.join(job.timeout)

        worker.raise(Timeout::Error, 'job exceeded timeout')
        return if worker.join(1)

        worker.kill
        worker.join(1)
      end
    end
  end
end
