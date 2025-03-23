# philiprehberger-cron_kit

[![Tests](https://github.com/philiprehberger/rb-cron-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-cron-kit/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-cron_kit.svg)](https://rubygems.org/gems/philiprehberger-cron_kit)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-cron-kit)](https://github.com/philiprehberger/rb-cron-kit/commits/main)

Cron expression parser and scheduler

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-cron_kit"
```

Or install directly:

```bash
gem install philiprehberger-cron_kit
```

## Usage

### Parsing Expressions

```ruby
require "philiprehberger/cron_kit"

expr = Philiprehberger::CronKit.parse("*/5 * * * *")

expr.match?(Time.new(2026, 3, 10, 12, 15)) # => true
expr.match?(Time.new(2026, 3, 10, 12, 13)) # => false

expr.next_at(from: Time.new(2026, 3, 10, 12, 13))
# => 2026-03-10 12:15:00

expr.to_s # => "*/5 * * * *"
```

### Timezone Support

Evaluate cron expressions in a specific timezone. Uses only stdlib — no external gems required.

```ruby
# Fixed UTC offset
expr = Philiprehberger::CronKit.parse("0 9 * * *", timezone: "+05:30")

# POSIX timezone name (resolved via ENV["TZ"])
expr = Philiprehberger::CronKit.parse("0 9 * * *", timezone: "US/Eastern")

# UTC shorthand
expr = Philiprehberger::CronKit.parse("0 9 * * *", timezone: "UTC")

expr.match?(some_time)       # evaluated in the configured timezone
expr.next_at(from: Time.now) # next match in that timezone
```

### Next Runs Preview

Get the next N upcoming execution times from a given start:

```ruby
expr = Philiprehberger::CronKit.parse("0 * * * *")

expr.next_runs(count: 5, from: Time.now)
# => [2026-03-17 14:00, 2026-03-17 15:00, 2026-03-17 16:00, ...]
```

### Previous Run

Find the most recent past match:

```ruby
expr = Philiprehberger::CronKit.parse("0 * * * *")

expr.previous_run(from: Time.now)
# => 2026-03-17 13:00:00
```

### Non-Standard Aliases

Use convenient shorthand aliases instead of full cron expressions:

```ruby
Philiprehberger::CronKit.parse("@hourly")   # => "0 * * * *"
Philiprehberger::CronKit.parse("@daily")    # => "0 0 * * *"
Philiprehberger::CronKit.parse("@weekly")   # => "0 0 * * 0"
Philiprehberger::CronKit.parse("@monthly")  # => "0 0 1 * *"
Philiprehberger::CronKit.parse("@yearly")   # => "0 0 1 1 *"
Philiprehberger::CronKit.parse("@annually") # => "0 0 1 1 *"
```

### Scheduling Jobs

```ruby
scheduler = Philiprehberger::CronKit.new

scheduler.every("0 9 * * 1-5") do |time|
  puts "Good morning! It's #{time}"
end

scheduler.every("*/10 * * * *") do
  puts "Running every 10 minutes"
end

scheduler.start   # runs in a background thread
scheduler.running? # => true
scheduler.stop
```

### Job Timeout

Kill jobs that exceed a time limit (in seconds). Timed-out jobs receive a `Timeout::Error` first, giving `ensure` blocks a chance to run before the thread is hard-killed.

```ruby
scheduler = Philiprehberger::CronKit.new

scheduler.every("*/5 * * * *", timeout: 30) do
  perform_work  # killed if it takes longer than 30 seconds
end
```

### Error Handling

Register a callback to handle job failures:

```ruby
scheduler = Philiprehberger::CronKit.new

scheduler.on_error do |job, error|
  puts "Job #{job.name} failed: #{error.message}"
end

scheduler.every("* * * * *", name: "risky") do
  might_fail
end
```

### Active Job Count

Check how many jobs are currently executing:

```ruby
scheduler.running_jobs # => 2
```

### Named Jobs

```ruby
scheduler = Philiprehberger::CronKit.new

scheduler.every("0 9 * * 1-5", name: "morning-report") do
  generate_report
end

scheduler.job_names     # => ["morning-report"]
scheduler.remove("morning-report")
```

### Inspecting Next Runs

```ruby
scheduler.next_runs(from: Time.now)
# => { "morning-report" => 2026-03-13 09:00:00 ... }
```

### Supported Syntax

| Token   | Example    | Description               |
|---------|------------|---------------------------|
| `*`     | `* * * * *` | Every possible value     |
| Value   | `5 * * * *` | Specific value           |
| Range   | `1-5`      | Values from 1 through 5   |
| Step    | `*/5`      | Every 5th value           |
| List    | `1,3,5`   | Values 1, 3, and 5        |
| Alias   | `@daily`   | Non-standard shorthand    |

### Fields

| Position | Field         | Range  |
|----------|---------------|--------|
| 1        | Minute        | 0-59   |
| 2        | Hour          | 0-23   |
| 3        | Day of month  | 1-31   |
| 4        | Month         | 1-12   |
| 5        | Day of week   | 0-6    |

## API

| Method | Description |
|--------|-------------|
| `Philiprehberger::CronKit.parse(expression, timezone: nil)` | Parse a cron expression, returns `Expression` |
| `Philiprehberger::CronKit.valid?(expression, timezone: nil)` | Return true if the expression parses without error |
| `Philiprehberger::CronKit.new` | Create a new `Scheduler` |
| `Expression#match?(time)` | Check if a Time matches the expression |
| `Expression#next_at(from:)` | Find the next matching Time |
| `Expression#next_runs(count: 5, from:)` | Return the next N matching times |
| `Expression#previous_run(from:)` | Find the most recent past match |
| `Expression#to_s` | Return the original expression string |
| `Expression#timezone` | Return the configured timezone (or nil) |
| `Scheduler#every(expression, name: nil, timeout: nil, &block)` | Register a cron job |
| `Scheduler#on_error(&block)` | Register a callback for job failures |
| `Scheduler#job_names` | List registered job names |
| `Scheduler#remove(name)` | Remove a job by name |
| `Scheduler#next_runs(from:)` | Hash of job names to their next scheduled time |
| `Scheduler#running_jobs` | Count of currently executing job threads |
| `Scheduler#start` | Start the scheduler in a background thread |
| `Scheduler#stop` | Stop the scheduler |
| `Scheduler#running?` | Check if the scheduler is running |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-cron-kit)

🐛 [Report issues](https://github.com/philiprehberger/rb-cron-kit/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-cron-kit/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
