# frozen_string_literal: true

require "spec_helper"

RSpec.describe Philiprehberger::CronKit do
  describe ".parse" do
    it "returns an Expression" do
      expr = described_class.parse("* * * * *")
      expect(expr).to be_a(Philiprehberger::CronKit::Expression)
    end
  end

  describe ".new" do
    it "returns a Scheduler" do
      scheduler = described_class.new
      expect(scheduler).to be_a(Philiprehberger::CronKit::Scheduler)
    end
  end
end

RSpec.describe Philiprehberger::CronKit::Expression do
  describe "#initialize" do
    it "parses a valid 5-field expression" do
      expect { described_class.new("0 12 * * 1") }.not_to raise_error
    end

    it "raises ParseError for too few fields" do
      expect { described_class.new("0 12 *") }.to raise_error(Philiprehberger::CronKit::ParseError, /expected 5 fields/)
    end

    it "raises ParseError for too many fields" do
      expect { described_class.new("0 12 * * * *") }.to raise_error(Philiprehberger::CronKit::ParseError)
    end

    it "raises ParseError for out-of-range values" do
      expect { described_class.new("60 * * * *") }.to raise_error(Philiprehberger::CronKit::ParseError)
    end

    it "raises ParseError for invalid tokens" do
      expect { described_class.new("abc * * * *") }.to raise_error(Philiprehberger::CronKit::ParseError)
    end

    it "raises ParseError for invalid range (low > high)" do
      expect { described_class.new("5-2 * * * *") }.to raise_error(Philiprehberger::CronKit::ParseError)
    end
  end

  describe "#match?" do
    it "matches every minute with * * * * *" do
      expr = described_class.new("* * * * *")
      expect(expr.match?(Time.new(2026, 3, 10, 14, 30))).to be true
    end

    it "matches a specific minute and hour" do
      expr = described_class.new("30 14 * * *")
      expect(expr.match?(Time.new(2026, 3, 10, 14, 30))).to be true
      expect(expr.match?(Time.new(2026, 3, 10, 14, 31))).to be false
    end

    it "matches with step values" do
      expr = described_class.new("*/15 * * * *")
      expect(expr.match?(Time.new(2026, 1, 1, 0, 0))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 15))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 30))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 7))).to be false
    end

    it "matches with ranges" do
      expr = described_class.new("0 9 * * 1-5")
      # Monday
      expect(expr.match?(Time.new(2026, 3, 9, 9, 0))).to be true
      # Sunday
      expect(expr.match?(Time.new(2026, 3, 8, 9, 0))).to be false
    end

    it "matches with lists" do
      expr = described_class.new("0,30 * * * *")
      expect(expr.match?(Time.new(2026, 1, 1, 12, 0))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 12, 30))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 12, 15))).to be false
    end

    it "matches day of month and month" do
      expr = described_class.new("0 0 25 12 *")
      expect(expr.match?(Time.new(2026, 12, 25, 0, 0))).to be true
      expect(expr.match?(Time.new(2026, 12, 26, 0, 0))).to be false
    end
  end

  describe "#next_at" do
    it "finds the next matching minute" do
      expr = described_class.new("30 * * * *")
      from = Time.new(2026, 3, 10, 12, 0, 0)
      result = expr.next_at(from: from)
      expect(result).to eq(Time.new(2026, 3, 10, 12, 30, 0, from.utc_offset))
    end

    it "advances to the next hour if current minute has passed" do
      expr = described_class.new("0 * * * *")
      from = Time.new(2026, 3, 10, 12, 30, 0)
      result = expr.next_at(from: from)
      expect(result).to eq(Time.new(2026, 3, 10, 13, 0, 0, from.utc_offset))
    end

    it "finds the next matching day" do
      expr = described_class.new("0 0 1 * *")
      from = Time.new(2026, 3, 10, 0, 0, 0)
      result = expr.next_at(from: from)
      expect(result).to eq(Time.new(2026, 4, 1, 0, 0, 0, from.utc_offset))
    end

    it "skips to the next minute from the given time" do
      expr = described_class.new("* * * * *")
      from = Time.new(2026, 3, 10, 12, 0, 0)
      result = expr.next_at(from: from)
      expect(result).to eq(Time.new(2026, 3, 10, 12, 1, 0, from.utc_offset))
    end
  end

  describe "#to_s" do
    it "returns the original expression" do
      expr = described_class.new("*/5 9-17 * * 1-5")
      expect(expr.to_s).to eq("*/5 9-17 * * 1-5")
    end
  end
end

RSpec.describe Philiprehberger::CronKit::Scheduler do
  subject(:scheduler) { described_class.new }

  after { scheduler.stop if scheduler.running? }

  describe "#every with name:" do
    it "registers a named job" do
      scheduler.every("* * * * *", name: "heartbeat") { nil }
      expect(scheduler.job_names).to eq(["heartbeat"])
    end

    it "allows jobs without a name" do
      scheduler.every("* * * * *") { nil }
      expect(scheduler.job_names).to be_empty
    end
  end

  describe "#job_names" do
    it "returns all registered named jobs" do
      scheduler.every("* * * * *", name: "alpha") { nil }
      scheduler.every("0 * * * *", name: "beta") { nil }
      scheduler.every("*/5 * * * *") { nil }
      expect(scheduler.job_names).to eq(%w[alpha beta])
    end
  end

  describe "#remove" do
    it "removes a job by name and returns true" do
      scheduler.every("* * * * *", name: "temp") { nil }
      expect(scheduler.remove("temp")).to be true
      expect(scheduler.job_names).to be_empty
    end

    it "returns false for an unknown name" do
      expect(scheduler.remove("nonexistent")).to be false
    end
  end

  describe "#next_runs" do
    it "returns a hash mapping names to next run times" do
      from = Time.new(2026, 3, 10, 12, 0, 0)
      scheduler.every("30 * * * *", name: "half_hour") { nil }
      scheduler.every("0 13 * * *", name: "one_pm") { nil }
      scheduler.every("*/5 * * * *") { nil } # unnamed, should be excluded

      result = scheduler.next_runs(from: from)

      expect(result.keys).to match_array(%w[half_hour one_pm])
      expect(result["half_hour"]).to eq(Time.new(2026, 3, 10, 12, 30, 0, from.utc_offset))
      expect(result["one_pm"]).to eq(Time.new(2026, 3, 10, 13, 0, 0, from.utc_offset))
    end
  end

  describe "threaded job execution" do
    it "executes matching jobs concurrently in separate threads" do
      results = Queue.new

      # Use an expression that matches the frozen time
      expr = Philiprehberger::CronKit::Expression.new("* * * * *")

      scheduler.every(expr, name: "slow") do |_t|
        results << [:slow, Thread.current.object_id]
        sleep 0.1
      end

      scheduler.every(expr, name: "fast") do |_t|
        results << [:fast, Thread.current.object_id]
      end

      # Directly call tick via send to test without starting the full loop
      scheduler.send(:tick)

      entries = []
      entries << results.pop until results.empty?

      names = entries.map(&:first)
      thread_ids = entries.map(&:last)

      expect(names).to contain_exactly(:slow, :fast)
      expect(thread_ids.uniq.size).to eq(2)
    end

    it "rescues errors in individual jobs without crashing" do
      called = false
      expr = Philiprehberger::CronKit::Expression.new("* * * * *")

      scheduler.every(expr, name: "failing") { raise StandardError, "boom" }
      scheduler.every(expr, name: "surviving") { called = true }

      expect { scheduler.send(:tick) }.not_to raise_error
      expect(called).to be true
    end
  end
end
