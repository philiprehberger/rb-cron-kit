# frozen_string_literal: true

module Philiprehberger
  module CronKit
    # Handles job execution with optional timeout enforcement.
    module TimeoutHandler
      private

      def start_job_thread(job, now)
        Thread.new(job, now) do |j, t|
          run_with_timeout(j, t)
        rescue StandardError
          # Prevent individual job errors from crashing the scheduler
        end
      end

      def run_with_timeout(job, time)
        if job.timeout
          execute_with_timeout(job, time)
        else
          job.block.call(time)
        end
      end

      def execute_with_timeout(job, time)
        worker = Thread.new { job.block.call(time) }
        unless worker.join(job.timeout)
          worker.kill
          worker.join(1)
        end
      end
    end
  end
end
