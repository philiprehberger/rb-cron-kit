# frozen_string_literal: true

require "spec_helper"

RSpec.describe Philiprehberger::CronKit do
  describe ".parse" do
    it "returns an Expression" do
      expr = described_class.parse("* * * * *")
      expect(expr).to be_a(Philiprehberger::CronKit::Expression)
    end

    it "accepts a timezone keyword" do
      expr = described_class.parse("0 9 * * *", timezone: "UTC")
      expect(expr.timezone).to eq("UTC")
    end

    it "expands aliases" do
      expr = described_class.parse("@daily")
      expect(expr.to_s).to eq("0 0 * * *")
    end
  end

  describe ".new" do
    it "returns a Scheduler" do
      scheduler = described_class.new
      expect(scheduler).to be_a(Philiprehberger::CronKit::Scheduler)
    end
  end
end

RSpec.describe Philiprehberger::CronKit::Aliases do
  describe ".expand" do
    it "expands @hourly" do
      expect(described_class.expand("@hourly")).to eq("0 * * * *")
    end

    it "expands @daily" do
      expect(described_class.expand("@daily")).to eq("0 0 * * *")
    end

    it "expands @weekly" do
      expect(described_class.expand("@weekly")).to eq("0 0 * * 0")
    end

    it "expands @monthly" do
      expect(described_class.expand("@monthly")).to eq("0 0 1 * *")
    end

    it "expands @yearly" do
      expect(described_class.expand("@yearly")).to eq("0 0 1 1 *")
    end

    it "expands @annually as synonym for @yearly" do
      expect(described_class.expand("@annually")).to eq("0 0 1 1 *")
    end

    it "is case-insensitive" do
      expect(described_class.expand("@DAILY")).to eq("0 0 * * *")
    end

    it "returns non-alias expressions unchanged" do
      expect(described_class.expand("*/5 * * * *")).to eq("*/5 * * * *")
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

    it "accepts non-standard aliases" do
      expr = described_class.new("@hourly")
      expect(expr.to_s).to eq("0 * * * *")
    end

    it "accepts a timezone option" do
      expr = described_class.new("0 9 * * *", timezone: "UTC")
      expect(expr.timezone).to eq("UTC")
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

    it "matches @daily alias at midnight" do
      expr = described_class.new("@daily")
      expect(expr.match?(Time.new(2026, 3, 10, 0, 0))).to be true
      expect(expr.match?(Time.new(2026, 3, 10, 12, 0))).to be false
    end
  end

  describe "#next_at" do
    it "finds the next matching minute" do
      expr = described_class.new("30 * * * *")
      from = Time.new(2026, 3, 10, 12, 0, 0)
      result = expr.next_at(from: from)
      expect(result.min).to eq(30)
      expect(result.hour).to eq(12)
    end

    it "advances to the next hour if current minute has passed" do
      expr = described_class.new("0 * * * *")
      from = Time.new(2026, 3, 10, 12, 30, 0)
      result = expr.next_at(from: from)
      expect(result.hour).to eq(13)
      expect(result.min).to eq(0)
    end

    it "finds the next matching day" do
      expr = described_class.new("0 0 1 * *")
      from = Time.new(2026, 3, 10, 0, 0, 0)
      result = expr.next_at(from: from)
      expect(result.month).to eq(4)
      expect(result.day).to eq(1)
    end

    it "skips to the next minute from the given time" do
      expr = described_class.new("* * * * *")
      from = Time.new(2026, 3, 10, 12, 0, 0)
      result = expr.next_at(from: from)
      expect(result.min).to eq(1)
    end
  end

  describe "#next_runs" do
    it "returns the specified number of upcoming matches" do
      expr = described_class.new("0 * * * *")
      from = Time.new(2026, 3, 10, 12, 0, 0)
      results = expr.next_runs(count: 3, from: from)

      expect(results.length).to eq(3)
      expect(results[0].hour).to eq(13)
      expect(results[1].hour).to eq(14)
      expect(results[2].hour).to eq(15)
    end

    it "defaults to 5 results" do
      expr = described_class.new("0 0 * * *")
      from = Time.new(2026, 3, 10, 0, 0, 0)
      results = expr.next_runs(from: from)

      expect(results.length).to eq(5)
    end

    it "works with step expressions" do
      expr = described_class.new("*/30 * * * *")
      from = Time.new(2026, 3, 10, 12, 0, 0)
      results = expr.next_runs(count: 4, from: from)

      expect(results.map(&:min)).to eq([30, 0, 30, 0])
    end

    it "returns consecutive results for every-minute" do
      expr = described_class.new("* * * * *")
      from = Time.new(2026, 3, 10, 12, 0, 0)
      results = expr.next_runs(count: 3, from: from)

      expect(results[0].min).to eq(1)
      expect(results[1].min).to eq(2)
      expect(results[2].min).to eq(3)
    end
  end

  describe "#previous_run" do
    it "finds the most recent past match" do
      expr = described_class.new("0 * * * *")
      from = Time.new(2026, 3, 10, 12, 30, 0)
      result = expr.previous_run(from: from)

      expect(result.hour).to eq(12)
      expect(result.min).to eq(0)
    end

    it "goes back to the previous hour if needed" do
      expr = described_class.new("30 * * * *")
      from = Time.new(2026, 3, 10, 12, 15, 0)
      result = expr.previous_run(from: from)

      expect(result.hour).to eq(11)
      expect(result.min).to eq(30)
    end

    it "finds previous day match" do
      expr = described_class.new("0 9 * * *")
      from = Time.new(2026, 3, 10, 8, 0, 0)
      result = expr.previous_run(from: from)

      expect(result.day).to eq(9)
      expect(result.hour).to eq(9)
    end

    it "finds previous match for @weekly" do
      expr = described_class.new("@weekly")
      from = Time.new(2026, 3, 11, 12, 0, 0) # Wednesday
      result = expr.previous_run(from: from)

      expect(result.wday).to eq(0) # Sunday
      expect(result.hour).to eq(0)
      expect(result.min).to eq(0)
    end
  end

  describe "timezone support" do
    it "evaluates match? in the specified timezone" do
      # UTC+0 expression; 9:00 UTC
      expr = described_class.new("0 9 * * *", timezone: "UTC")
      utc_time = Time.new(2026, 3, 10, 9, 0, 0, 0)
      expect(expr.match?(utc_time)).to be true
    end

    it "does not match when timezone differs" do
      expr = described_class.new("0 9 * * *", timezone: "UTC")
      # 9:00 in +05:00 is 04:00 UTC
      offset_time = Time.new(2026, 3, 10, 9, 0, 0, 5 * 3600)
      expect(expr.match?(offset_time)).to be false
    end

    it "stores the timezone" do
      expr = described_class.new("0 9 * * *", timezone: "US/Eastern")
      expect(expr.timezone).to eq("US/Eastern")
    end

    it "works with fixed offset timezones" do
      expr = described_class.new("0 9 * * *", timezone: "+05:30")
      expect(expr.timezone).to eq("+05:30")
    end
  end

  describe "#to_s" do
    it "returns the original expression" do
      expr = described_class.new("*/5 9-17 * * 1-5")
      expect(expr.to_s).to eq("*/5 9-17 * * 1-5")
    end

    it "returns the expanded alias" do
      expr = described_class.new("@monthly")
      expect(expr.to_s).to eq("0 0 1 * *")
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

  describe "#every with timeout:" do
    it "registers a job with a timeout" do
      scheduler.every("* * * * *", name: "limited", timeout: 5) { nil }
      expect(scheduler.job_names).to eq(["limited"])
    end

    it "kills a job that exceeds the timeout" do
      completed = false
      expr = Philiprehberger::CronKit::Expression.new("* * * * *")

      scheduler.every(expr, name: "slow", timeout: 0.1) do
        sleep 10
        completed = true
      end

      scheduler.send(:tick)
      expect(completed).to be false
    end

    it "allows a job that finishes within the timeout" do
      result = Queue.new
      expr = Philiprehberger::CronKit::Expression.new("* * * * *")

      scheduler.every(expr, name: "fast", timeout: 5) do
        result << :done
      end

      scheduler.send(:tick)
      expect(result.pop(true)).to eq(:done)
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
      expect(result["half_hour"].min).to eq(30)
      expect(result["one_pm"].hour).to eq(13)
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

  describe "alias support in scheduler" do
    it "accepts @daily alias" do
      scheduler.every("@daily", name: "daily-job") { nil }
      expect(scheduler.job_names).to eq(["daily-job"])
    end
  end
end
