# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::CronKit do
  describe '.parse' do
    it 'returns an Expression' do
      expr = described_class.parse('* * * * *')
      expect(expr).to be_a(Philiprehberger::CronKit::Expression)
    end

    it 'accepts a timezone keyword' do
      expr = described_class.parse('0 9 * * *', timezone: 'UTC')
      expect(expr.timezone).to eq('UTC')
    end

    it 'expands aliases' do
      expr = described_class.parse('@daily')
      expect(expr.to_s).to eq('0 0 * * *')
    end
  end

  describe '.new' do
    it 'returns a Scheduler' do
      scheduler = described_class.new
      expect(scheduler).to be_a(Philiprehberger::CronKit::Scheduler)
    end
  end
end

RSpec.describe Philiprehberger::CronKit::Aliases do
  describe '.expand' do
    it 'expands @hourly' do
      expect(described_class.expand('@hourly')).to eq('0 * * * *')
    end

    it 'expands @daily' do
      expect(described_class.expand('@daily')).to eq('0 0 * * *')
    end

    it 'expands @weekly' do
      expect(described_class.expand('@weekly')).to eq('0 0 * * 0')
    end

    it 'expands @monthly' do
      expect(described_class.expand('@monthly')).to eq('0 0 1 * *')
    end

    it 'expands @yearly' do
      expect(described_class.expand('@yearly')).to eq('0 0 1 1 *')
    end

    it 'expands @annually as synonym for @yearly' do
      expect(described_class.expand('@annually')).to eq('0 0 1 1 *')
    end

    it 'is case-insensitive' do
      expect(described_class.expand('@DAILY')).to eq('0 0 * * *')
    end

    it 'returns non-alias expressions unchanged' do
      expect(described_class.expand('*/5 * * * *')).to eq('*/5 * * * *')
    end
  end
end

RSpec.describe Philiprehberger::CronKit::Expression do
  describe '#initialize' do
    it 'parses a valid 5-field expression' do
      expect { described_class.new('0 12 * * 1') }.not_to raise_error
    end

    it 'raises ParseError for too few fields' do
      expect { described_class.new('0 12 *') }.to raise_error(Philiprehberger::CronKit::ParseError, /expected 5 fields/)
    end

    it 'raises ParseError for too many fields' do
      expect { described_class.new('0 12 * * * *') }.to raise_error(Philiprehberger::CronKit::ParseError)
    end

    it 'raises ParseError for out-of-range values' do
      expect { described_class.new('60 * * * *') }.to raise_error(Philiprehberger::CronKit::ParseError)
    end

    it 'raises ParseError for invalid tokens' do
      expect { described_class.new('abc * * * *') }.to raise_error(Philiprehberger::CronKit::ParseError)
    end

    it 'raises ParseError for invalid range (low > high)' do
      expect { described_class.new('5-2 * * * *') }.to raise_error(Philiprehberger::CronKit::ParseError)
    end

    it 'accepts non-standard aliases' do
      expr = described_class.new('@hourly')
      expect(expr.to_s).to eq('0 * * * *')
    end

    it 'accepts a timezone option' do
      expr = described_class.new('0 9 * * *', timezone: 'UTC')
      expect(expr.timezone).to eq('UTC')
    end
  end

  describe '#match?' do
    it 'matches every minute with * * * * *' do
      expr = described_class.new('* * * * *')
      expect(expr.match?(Time.new(2026, 3, 10, 14, 30))).to be true
    end

    it 'matches a specific minute and hour' do
      expr = described_class.new('30 14 * * *')
      expect(expr.match?(Time.new(2026, 3, 10, 14, 30))).to be true
      expect(expr.match?(Time.new(2026, 3, 10, 14, 31))).to be false
    end

    it 'matches with step values' do
      expr = described_class.new('*/15 * * * *')
      expect(expr.match?(Time.new(2026, 1, 1, 0, 0))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 15))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 30))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 7))).to be false
    end

    it 'matches with ranges' do
      expr = described_class.new('0 9 * * 1-5')
      # Monday
      expect(expr.match?(Time.new(2026, 3, 9, 9, 0))).to be true
      # Sunday
      expect(expr.match?(Time.new(2026, 3, 8, 9, 0))).to be false
    end

    it 'matches with lists' do
      expr = described_class.new('0,30 * * * *')
      expect(expr.match?(Time.new(2026, 1, 1, 12, 0))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 12, 30))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 12, 15))).to be false
    end

    it 'matches day of month and month' do
      expr = described_class.new('0 0 25 12 *')
      expect(expr.match?(Time.new(2026, 12, 25, 0, 0))).to be true
      expect(expr.match?(Time.new(2026, 12, 26, 0, 0))).to be false
    end

    it 'matches @daily alias at midnight' do
      expr = described_class.new('@daily')
      expect(expr.match?(Time.new(2026, 3, 10, 0, 0))).to be true
      expect(expr.match?(Time.new(2026, 3, 10, 12, 0))).to be false
    end
  end

  describe '#matches_any?' do
    it 'returns true when at least one time matches' do
      expr = described_class.new('0 9 * * *')
      times = [
        Time.new(2026, 3, 10, 8, 30),
        Time.new(2026, 3, 10, 9, 0),
        Time.new(2026, 3, 10, 10, 0)
      ]
      expect(expr.matches_any?(times)).to be true
    end

    it 'returns false when no time matches' do
      expr = described_class.new('0 9 * * *')
      times = [
        Time.new(2026, 3, 10, 8, 30),
        Time.new(2026, 3, 10, 10, 0),
        Time.new(2026, 3, 10, 11, 0)
      ]
      expect(expr.matches_any?(times)).to be false
    end

    it 'returns false on an empty enumerable' do
      expr = described_class.new('* * * * *')
      expect(expr.matches_any?([])).to be false
    end

    it 'accepts any enumerable (not just Array)' do
      expr = described_class.new('30 * * * *')
      enum = [Time.new(2026, 3, 10, 12, 30)].each
      expect(expr.matches_any?(enum)).to be true
    end

    it 'short-circuits on the first match' do
      expr = described_class.new('0 9 * * *')
      inspected = []
      times = [
        Time.new(2026, 3, 10, 9, 0),
        Time.new(2026, 3, 10, 10, 0),
        Time.new(2026, 3, 10, 11, 0)
      ]
      enum = Enumerator.new do |y|
        times.each do |t|
          inspected << t
          y << t
        end
      end

      expect(expr.matches_any?(enum)).to be true
      expect(inspected.length).to eq(1)
    end
  end

  describe '#next_at' do
    it 'finds the next matching minute' do
      expr = described_class.new('30 * * * *')
      from = Time.new(2026, 3, 10, 12, 0, 0)
      result = expr.next_at(from: from)
      expect(result.min).to eq(30)
      expect(result.hour).to eq(12)
    end

    it 'advances to the next hour if current minute has passed' do
      expr = described_class.new('0 * * * *')
      from = Time.new(2026, 3, 10, 12, 30, 0)
      result = expr.next_at(from: from)
      expect(result.hour).to eq(13)
      expect(result.min).to eq(0)
    end

    it 'finds the next matching day' do
      expr = described_class.new('0 0 1 * *')
      from = Time.new(2026, 3, 10, 0, 0, 0)
      result = expr.next_at(from: from)
      expect(result.month).to eq(4)
      expect(result.day).to eq(1)
    end

    it 'skips to the next minute from the given time' do
      expr = described_class.new('* * * * *')
      from = Time.new(2026, 3, 10, 12, 0, 0)
      result = expr.next_at(from: from)
      expect(result.min).to eq(1)
    end
  end

  describe '#next_runs' do
    it 'returns the specified number of upcoming matches' do
      expr = described_class.new('0 * * * *')
      from = Time.new(2026, 3, 10, 12, 0, 0)
      results = expr.next_runs(count: 3, from: from)

      expect(results.length).to eq(3)
      expect(results[0].hour).to eq(13)
      expect(results[1].hour).to eq(14)
      expect(results[2].hour).to eq(15)
    end

    it 'defaults to 5 results' do
      expr = described_class.new('0 0 * * *')
      from = Time.new(2026, 3, 10, 0, 0, 0)
      results = expr.next_runs(from: from)

      expect(results.length).to eq(5)
    end

    it 'works with step expressions' do
      expr = described_class.new('*/30 * * * *')
      from = Time.new(2026, 3, 10, 12, 0, 0)
      results = expr.next_runs(count: 4, from: from)

      expect(results.map(&:min)).to eq([30, 0, 30, 0])
    end

    it 'returns consecutive results for every-minute' do
      expr = described_class.new('* * * * *')
      from = Time.new(2026, 3, 10, 12, 0, 0)
      results = expr.next_runs(count: 3, from: from)

      expect(results[0].min).to eq(1)
      expect(results[1].min).to eq(2)
      expect(results[2].min).to eq(3)
    end

    it 'returns results in strictly ascending order' do
      expr = described_class.new('0,30 9-17 * * 1-5')
      from = Time.new(2026, 3, 9, 8, 0, 0) # Monday morning
      results = expr.next_runs(count: 6, from: from)

      results.each_cons(2) do |a, b|
        expect(a).to be < b
      end
    end
  end

  describe '#previous_run' do
    it 'finds the most recent past match' do
      expr = described_class.new('0 * * * *')
      from = Time.new(2026, 3, 10, 12, 30, 0)
      result = expr.previous_run(from: from)

      expect(result.hour).to eq(12)
      expect(result.min).to eq(0)
    end

    it 'goes back to the previous hour if needed' do
      expr = described_class.new('30 * * * *')
      from = Time.new(2026, 3, 10, 12, 15, 0)
      result = expr.previous_run(from: from)

      expect(result.hour).to eq(11)
      expect(result.min).to eq(30)
    end

    it 'finds previous day match' do
      expr = described_class.new('0 9 * * *')
      from = Time.new(2026, 3, 10, 8, 0, 0)
      result = expr.previous_run(from: from)

      expect(result.day).to eq(9)
      expect(result.hour).to eq(9)
    end

    it 'finds previous match for @weekly' do
      expr = described_class.new('@weekly')
      from = Time.new(2026, 3, 11, 12, 0, 0) # Wednesday
      result = expr.previous_run(from: from)

      expect(result.wday).to eq(0) # Sunday
      expect(result.hour).to eq(0)
      expect(result.min).to eq(0)
    end
  end

  describe 'timezone support' do
    it 'evaluates match? in the specified timezone' do
      # UTC+0 expression; 9:00 UTC
      expr = described_class.new('0 9 * * *', timezone: 'UTC')
      utc_time = Time.new(2026, 3, 10, 9, 0, 0, 0)
      expect(expr.match?(utc_time)).to be true
    end

    it 'does not match when timezone differs' do
      expr = described_class.new('0 9 * * *', timezone: 'UTC')
      # 9:00 in +05:00 is 04:00 UTC
      offset_time = Time.new(2026, 3, 10, 9, 0, 0, 5 * 3600)
      expect(expr.match?(offset_time)).to be false
    end

    it 'stores the timezone' do
      expr = described_class.new('0 9 * * *', timezone: 'US/Eastern')
      expect(expr.timezone).to eq('US/Eastern')
    end

    it 'works with fixed offset timezones' do
      expr = described_class.new('0 9 * * *', timezone: '+05:30')
      expect(expr.timezone).to eq('+05:30')
    end
  end

  describe '#to_s' do
    it 'returns the original expression' do
      expr = described_class.new('*/5 9-17 * * 1-5')
      expect(expr.to_s).to eq('*/5 9-17 * * 1-5')
    end

    it 'returns the expanded alias' do
      expr = described_class.new('@monthly')
      expect(expr.to_s).to eq('0 0 1 * *')
    end
  end

  describe '#raw' do
    it 'exposes the raw expression string' do
      expr = described_class.new('5 4 * * *')
      expect(expr.raw).to eq('5 4 * * *')
    end
  end

  describe 'parser edge cases' do
    it 'parses range-step syntax (1-10/3)' do
      expr = described_class.new('1-10/3 * * * *')
      expect(expr.match?(Time.new(2026, 1, 1, 0, 1))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 4))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 7))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 10))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 2))).to be false
    end

    it 'raises ParseError for step of zero' do
      expect do
        described_class.new('*/0 * * * *')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /step must be > 0/)
    end

    it 'raises ParseError for zero step in range-step' do
      expect do
        described_class.new('1-10/0 * * * *')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /step must be > 0/)
    end

    it 'raises ParseError for out-of-range low value in range' do
      expect do
        described_class.new('* * 0-15 * *')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /outside allowed range/)
    end

    it 'raises ParseError for out-of-range high value in range' do
      expect do
        described_class.new('* * 1-32 * *')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /outside allowed range/)
    end

    it 'raises ParseError for hour value of 24' do
      expect do
        described_class.new('0 24 * * *')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /outside allowed range/)
    end

    it 'raises ParseError for month value of 0' do
      expect do
        described_class.new('0 0 1 0 *')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /outside allowed range/)
    end

    it 'raises ParseError for month value of 13' do
      expect do
        described_class.new('0 0 1 13 *')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /outside allowed range/)
    end

    it 'raises ParseError for day-of-week value of 7' do
      expect do
        described_class.new('0 0 * * 7')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /outside allowed range/)
    end

    it 'raises ParseError for an empty string' do
      expect { described_class.new('') }.to raise_error(Philiprehberger::CronKit::ParseError, /expected 5 fields/)
    end

    it 'raises ParseError for whitespace-only input' do
      expect { described_class.new('   ') }.to raise_error(Philiprehberger::CronKit::ParseError, /expected 5 fields/)
    end

    it 'handles leading and trailing whitespace in valid expressions' do
      expr = described_class.new('  0 0 * * *  ')
      expect(expr.match?(Time.new(2026, 1, 1, 0, 0))).to be true
    end

    it 'parses lists combined with ranges' do
      expr = described_class.new('0,15-20 * * * *')
      expect(expr.match?(Time.new(2026, 1, 1, 0, 0))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 17))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 10))).to be false
    end

    it 'raises ParseError for inverted range in range-step' do
      expect do
        described_class.new('10-5/2 * * * *')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /low > high/)
    end

    it 'raises ParseError for out-of-range values in range-step' do
      expect do
        described_class.new('0-60/5 * * * *')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /outside allowed range/)
    end

    it 'raises ParseError for day-of-month value of 0' do
      expect do
        described_class.new('0 0 0 * *')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /outside allowed range/)
    end

    it 'raises ParseError for minute value of 60 in a list' do
      expect do
        described_class.new('0,60 * * * *')
      end.to raise_error(Philiprehberger::CronKit::ParseError, /outside allowed range/)
    end

    it 'parses full day-of-week range 0-6' do
      expr = described_class.new('0 0 * * 0-6')
      (0..6).each do |wday|
        # Find a date in March 2026 with the target wday
        day = (1..7).find { |d| Time.new(2026, 3, d).wday == wday }
        expect(expr.match?(Time.new(2026, 3, day, 0, 0))).to be true
      end
    end

    it 'parses a single-value list (no comma)' do
      expr = described_class.new('5 * * * *')
      expect(expr.match?(Time.new(2026, 1, 1, 0, 5))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 6))).to be false
    end

    it 'handles duplicate values in a list' do
      expr = described_class.new('5,5,5 * * * *')
      expect(expr.match?(Time.new(2026, 1, 1, 0, 5))).to be true
      expect(expr.match?(Time.new(2026, 1, 1, 0, 6))).to be false
    end
  end

  describe 'leap year and month boundary edge cases' do
    it 'matches February 29 on a leap year' do
      expr = described_class.new('0 0 29 2 *')
      expect(expr.match?(Time.new(2028, 2, 29, 0, 0))).to be true
    end

    it 'does not match February 29 on a non-leap year date' do
      expr = described_class.new('0 0 29 2 *')
      expect(expr.match?(Time.new(2026, 2, 28, 0, 0))).to be false
    end

    it 'finds next Feb 29 occurrence from a non-leap year' do
      expr = described_class.new('0 0 29 2 *')
      from = Time.new(2026, 3, 1, 0, 0, 0)
      result = expr.next_at(from: from)
      expect(result.year).to eq(2028)
      expect(result.month).to eq(2)
      expect(result.day).to eq(29)
    end

    it 'matches the 31st only in months that have 31 days' do
      expr = described_class.new('0 0 31 * *')
      expect(expr.match?(Time.new(2026, 1, 31, 0, 0))).to be true
      expect(expr.match?(Time.new(2026, 3, 31, 0, 0))).to be true
    end

    it 'finds next_at across month boundary from end of short month' do
      expr = described_class.new('0 0 31 * *')
      from = Time.new(2026, 2, 28, 0, 0, 0)
      result = expr.next_at(from: from)
      expect(result.month).to eq(3)
      expect(result.day).to eq(31)
    end

    it 'finds previous_run for Feb 29 going back to last leap year' do
      expr = described_class.new('0 0 29 2 *')
      from = Time.new(2026, 3, 1, 0, 0, 0)
      result = expr.previous_run(from: from)
      expect(result.year).to eq(2024)
      expect(result.month).to eq(2)
      expect(result.day).to eq(29)
    end
  end

  describe 'leap year and month boundary edge cases (extended)' do
    it 'finds next_at for the 30th skipping February' do
      expr = described_class.new('0 0 30 * *')
      from = Time.new(2026, 1, 31, 0, 0, 0)
      result = expr.next_at(from: from)
      # February has no 30th, so next match is March 30
      expect(result.month).to eq(3)
      expect(result.day).to eq(30)
    end

    it 'matches end-of-year boundary (Dec 31 23:59)' do
      expr = described_class.new('59 23 31 12 *')
      expect(expr.match?(Time.new(2026, 12, 31, 23, 59))).to be true
    end

    it 'matches start-of-year boundary (Jan 1 00:00)' do
      expr = described_class.new('0 0 1 1 *')
      expect(expr.match?(Time.new(2027, 1, 1, 0, 0))).to be true
    end
  end

  describe '#next_at across year boundary' do
    it 'finds the next match when it falls in the following year' do
      expr = described_class.new('0 0 1 1 *')
      from = Time.new(2026, 6, 15, 0, 0, 0)
      result = expr.next_at(from: from)
      expect(result.year).to eq(2027)
      expect(result.month).to eq(1)
      expect(result.day).to eq(1)
    end
  end

  describe '#match? with combined field constraints' do
    it 'requires all five fields to match simultaneously' do
      # 0 9 15 6 1 = minute 0, hour 9, day 15, month June, Monday
      expr = described_class.new('0 9 15 6 1')
      # June 15, 2026 is a Monday
      expect(expr.match?(Time.new(2026, 6, 15, 9, 0))).to be true
      # Right time/date but wrong day-of-week (June 16 is Tuesday)
      expect(expr.match?(Time.new(2026, 6, 16, 9, 0))).to be false
    end

    it 'matches day-of-week 0 for Sunday' do
      expr = described_class.new('0 0 * * 0')
      # March 8, 2026 is a Sunday
      expect(expr.match?(Time.new(2026, 3, 8, 0, 0))).to be true
      expect(expr.match?(Time.new(2026, 3, 9, 0, 0))).to be false
    end

    it 'matches day-of-week 6 for Saturday' do
      expr = described_class.new('0 0 * * 6')
      # March 7, 2026 is a Saturday
      expect(expr.match?(Time.new(2026, 3, 7, 0, 0))).to be true
      expect(expr.match?(Time.new(2026, 3, 8, 0, 0))).to be false
    end
  end
end

RSpec.describe Philiprehberger::CronKit::Timezone do
  describe '.utc_offset_for' do
    it 'returns nil for nil timezone' do
      expect(described_class.utc_offset_for(nil)).to be_nil
    end

    it 'returns 0 for UTC' do
      expect(described_class.utc_offset_for('UTC')).to eq(0)
    end

    it 'is case-insensitive for UTC' do
      expect(described_class.utc_offset_for('utc')).to eq(0)
    end

    it 'parses positive fixed offset +05:30' do
      expect(described_class.utc_offset_for('+05:30')).to eq((5 * 3600) + (30 * 60))
    end

    it 'parses negative fixed offset -04:00' do
      expect(described_class.utc_offset_for('-04:00')).to eq(-4 * 3600)
    end

    it 'parses +00:00 as zero' do
      expect(described_class.utc_offset_for('+00:00')).to eq(0)
    end

    it 'parses single-digit hour offset +5:00' do
      expect(described_class.utc_offset_for('+5:00')).to eq(5 * 3600)
    end
  end

  describe '.apply' do
    it 'creates a Time with the specified offset' do
      base = Time.new(2026, 6, 15, 12, 30, 0, 0)
      result = described_class.apply(base, 3600)
      expect(result.utc_offset).to eq(3600)
      expect(result.hour).to eq(12)
      expect(result.min).to eq(30)
    end

    it 'preserves all time components' do
      base = Time.new(2026, 12, 25, 23, 59, 45, 0)
      result = described_class.apply(base, -18_000)
      expect(result.year).to eq(2026)
      expect(result.month).to eq(12)
      expect(result.day).to eq(25)
      expect(result.hour).to eq(23)
      expect(result.min).to eq(59)
      expect(result.sec).to eq(45)
    end

    it 'applies zero offset correctly' do
      base = Time.new(2026, 1, 1, 0, 0, 0, 0)
      result = described_class.apply(base, 0)
      expect(result.utc_offset).to eq(0)
      expect(result.hour).to eq(0)
    end

    it 'applies negative offset correctly' do
      base = Time.new(2026, 7, 4, 18, 0, 0, 0)
      result = described_class.apply(base, -5 * 3600)
      expect(result.utc_offset).to eq(-18_000)
      expect(result.hour).to eq(18)
    end
  end
end

RSpec.describe Philiprehberger::CronKit::Scheduler do
  subject(:scheduler) { described_class.new }

  after { scheduler.stop if scheduler.running? }

  describe '#every with name:' do
    it 'registers a named job' do
      scheduler.every('* * * * *', name: 'heartbeat') { nil }
      expect(scheduler.job_names).to eq(['heartbeat'])
    end

    it 'allows jobs without a name' do
      scheduler.every('* * * * *') { nil }
      expect(scheduler.job_names).to be_empty
    end
  end

  describe '#every with timeout:' do
    it 'registers a job with a timeout' do
      scheduler.every('* * * * *', name: 'limited', timeout: 5) { nil }
      expect(scheduler.job_names).to eq(['limited'])
    end

    it 'kills a job that exceeds the timeout' do
      completed = false
      expr = Philiprehberger::CronKit::Expression.new('* * * * *')

      scheduler.every(expr, name: 'slow', timeout: 0.1) do
        sleep 10
        completed = true
      end

      scheduler.send(:tick)
      expect(completed).to be false
    end

    it 'allows a job that finishes within the timeout' do
      result = Queue.new
      expr = Philiprehberger::CronKit::Expression.new('* * * * *')

      scheduler.every(expr, name: 'fast', timeout: 5) do
        result << :done
      end

      scheduler.send(:tick)
      expect(result.pop(true)).to eq(:done)
    end
  end

  describe '#job_names' do
    it 'returns all registered named jobs' do
      scheduler.every('* * * * *', name: 'alpha') { nil }
      scheduler.every('0 * * * *', name: 'beta') { nil }
      scheduler.every('*/5 * * * *') { nil }
      expect(scheduler.job_names).to eq(%w[alpha beta])
    end
  end

  describe '#remove' do
    it 'removes a job by name and returns true' do
      scheduler.every('* * * * *', name: 'temp') { nil }
      expect(scheduler.remove('temp')).to be true
      expect(scheduler.job_names).to be_empty
    end

    it 'returns false for an unknown name' do
      expect(scheduler.remove('nonexistent')).to be false
    end
  end

  describe '#next_runs' do
    it 'returns a hash mapping names to next run times' do
      from = Time.new(2026, 3, 10, 12, 0, 0)
      scheduler.every('30 * * * *', name: 'half_hour') { nil }
      scheduler.every('0 13 * * *', name: 'one_pm') { nil }
      scheduler.every('*/5 * * * *') { nil } # unnamed, should be excluded

      result = scheduler.next_runs(from: from)

      expect(result.keys).to match_array(%w[half_hour one_pm])
      expect(result['half_hour'].min).to eq(30)
      expect(result['one_pm'].hour).to eq(13)
    end
  end

  describe 'threaded job execution' do
    it 'executes matching jobs concurrently in separate threads' do
      results = Queue.new

      # Use an expression that matches the frozen time
      expr = Philiprehberger::CronKit::Expression.new('* * * * *')

      scheduler.every(expr, name: 'slow') do |_t|
        results << [:slow, Thread.current.object_id]
        sleep 0.1
      end

      scheduler.every(expr, name: 'fast') do |_t|
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

    it 'rescues errors in individual jobs without crashing' do
      called = false
      expr = Philiprehberger::CronKit::Expression.new('* * * * *')

      scheduler.every(expr, name: 'failing') { raise StandardError, 'boom' }
      scheduler.every(expr, name: 'surviving') { called = true }

      expect { scheduler.send(:tick) }.not_to raise_error
      expect(called).to be true
    end
  end

  describe 'alias support in scheduler' do
    it 'accepts @daily alias' do
      scheduler.every('@daily', name: 'daily-job') { nil }
      expect(scheduler.job_names).to eq(['daily-job'])
    end
  end

  describe '#every chainability' do
    it 'returns self to allow method chaining' do
      result = scheduler.every('* * * * *', name: 'a') { nil }
      expect(result).to equal(scheduler)
    end
  end

  describe '#every with Expression object' do
    it 'accepts a pre-built Expression instead of a string' do
      expr = Philiprehberger::CronKit::Expression.new('*/10 * * * *')
      scheduler.every(expr, name: 'pre-built') { nil }
      expect(scheduler.job_names).to eq(['pre-built'])
    end
  end

  describe '#start and #stop lifecycle' do
    it 'reports running? as true after start' do
      scheduler.start
      expect(scheduler.running?).to be true
    end

    it 'reports running? as false after stop' do
      scheduler.start
      scheduler.stop
      expect(scheduler.running?).to be false
    end

    it 'is idempotent — calling start twice returns self without error' do
      result1 = scheduler.start
      result2 = scheduler.start
      expect(result1).to equal(scheduler)
      expect(result2).to equal(scheduler)
      expect(scheduler.running?).to be true
    end
  end

  describe '#next_runs with no jobs' do
    it 'returns an empty hash' do
      expect(scheduler.next_runs).to eq({})
    end
  end

  describe '#remove leaves other jobs intact' do
    it 'only removes the targeted job' do
      scheduler.every('* * * * *', name: 'keep') { nil }
      scheduler.every('* * * * *', name: 'drop') { nil }
      scheduler.remove('drop')
      expect(scheduler.job_names).to eq(['keep'])
    end
  end

  describe '#on_error' do
    it 'invokes the callback when a job raises' do
      captured_error = nil
      captured_job = nil
      expr = Philiprehberger::CronKit::Expression.new('* * * * *')

      scheduler.on_error do |job, error|
        captured_job = job
        captured_error = error
      end

      scheduler.every(expr, name: 'broken') { raise StandardError, 'test error' }
      scheduler.send(:tick)

      expect(captured_error).to be_a(StandardError)
      expect(captured_error.message).to eq('test error')
      expect(captured_job.name).to eq('broken')
    end

    it 'returns the callback when called without a block' do
      blk = proc { |_j, _e| }
      scheduler.on_error(&blk)
      expect(scheduler.on_error).to eq(blk)
    end
  end

  describe '#running_jobs' do
    it 'returns the count of currently executing job threads' do
      started = Queue.new
      finish = Queue.new
      expr = Philiprehberger::CronKit::Expression.new('* * * * *')

      scheduler.every(expr, name: 'slow') do
        started << :go
        finish.pop
      end

      thread = Thread.new { scheduler.send(:tick) }
      started.pop # wait until the job has started

      expect(scheduler.running_jobs).to eq(1)

      finish << :done
      thread.join(5)

      expect(scheduler.running_jobs).to eq(0)
    end
  end

  describe '#every with overlap: false' do
    it 'skips execution when the previous run is still active' do
      ran = Queue.new
      started = Queue.new
      finish = Queue.new
      expr = Philiprehberger::CronKit::Expression.new('* * * * *')

      scheduler.every(expr, name: 'slow', overlap: false) do
        started << :go
        finish.pop
        ran << :ran
      end

      t1 = Thread.new { scheduler.send(:tick) }
      started.pop

      t2 = Thread.new { scheduler.send(:tick) }
      t2.join(5)

      finish << :done
      t1.join(5)

      count = 0
      loop do
        ran.pop(true)
        count += 1
      rescue ThreadError
        break
      end
      expect(count).to eq(1)
    end

    it 'runs normally when previous run has completed' do
      call_count = 0
      mutex = Mutex.new
      expr = Philiprehberger::CronKit::Expression.new('* * * * *')

      scheduler.every(expr, name: 'fast', overlap: false) do
        mutex.synchronize { call_count += 1 }
      end

      scheduler.send(:tick)
      scheduler.send(:tick)

      expect(call_count).to eq(2)
    end

    it 'allows overlap by default' do
      started = Queue.new
      finish = Queue.new
      call_count = Queue.new
      expr = Philiprehberger::CronKit::Expression.new('* * * * *')

      scheduler.every(expr, name: 'default') do
        call_count << :ran
        started << :go
        finish.pop
      end

      t1 = Thread.new { scheduler.send(:tick) }
      started.pop

      t2 = Thread.new { scheduler.send(:tick) }
      started.pop

      2.times { finish << :done }
      t1.join(5)
      t2.join(5)

      count = 0
      loop do
        call_count.pop(true)
        count += 1
      rescue ThreadError
        break
      end
      expect(count).to eq(2)
    end
  end

  describe 'graceful timeout' do
    it 'gives ensure blocks a chance to run before hard-killing' do
      ensure_ran = Queue.new
      expr = Philiprehberger::CronKit::Expression.new('* * * * *')

      scheduler.every(expr, name: 'stuck', timeout: 0.1) do
        sleep 10
      ensure
        ensure_ran << :cleaned_up
      end

      scheduler.send(:tick)
      result = begin
        ensure_ran.pop(timeout: 5)
      rescue StandardError
        nil
      end
      expect(result).to eq(:cleaned_up)
    end
  end

  describe '#run_now' do
    it 'manually triggers a registered job and returns its value' do
      scheduler = Philiprehberger::CronKit::Scheduler.new
      scheduler.every('@hourly', name: :work) { 42 }

      expect(scheduler.run_now(:work)).to eq(42)
    end

    it 'raises KeyError for an unknown job name' do
      scheduler = Philiprehberger::CronKit::Scheduler.new
      expect { scheduler.run_now(:missing) }.to raise_error(KeyError)
    end

    it 'honors timeout: by raising Timeout::Error' do
      scheduler = Philiprehberger::CronKit::Scheduler.new
      scheduler.every('@hourly', name: :slow, timeout: 0.05) { sleep 1 }

      expect { scheduler.run_now(:slow) }.to raise_error(Timeout::Error)
    end

    it 'returns nil when overlap: false and the job is already running' do
      scheduler = Philiprehberger::CronKit::Scheduler.new
      gate = Queue.new
      release = Queue.new
      scheduler.every('@hourly', name: :exclusive, overlap: false) do
        gate << :started
        release.pop
      end

      thread = Thread.new { scheduler.run_now(:exclusive) }
      gate.pop # ensure first run is in flight

      expect(scheduler.run_now(:exclusive)).to be_nil

      release << :go
      thread.join
    end

    it 'propagates errors from the job block' do
      scheduler = Philiprehberger::CronKit::Scheduler.new
      scheduler.every('@hourly', name: :boom) { raise 'boom' }

      expect { scheduler.run_now(:boom) }.to raise_error(StandardError, 'boom')
    end
  end
end
