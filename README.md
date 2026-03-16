# philiprehberger-cron_kit

[![Gem Version](https://badge.fury.io/rb/philiprehberger-cron_kit.svg)](https://badge.fury.io/rb/philiprehberger-cron_kit)
[![CI](https://github.com/philiprehberger/rb-cron-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-cron-kit/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/philiprehberger/rb-cron-kit)](LICENSE)

Cron expression parser and scheduler for Ruby. Zero dependencies.

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-cron_kit"
```

Or install directly:

```sh
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
| `Philiprehberger::CronKit.parse(expression)` | Parse a cron expression, returns `Expression` |
| `Philiprehberger::CronKit.new` | Create a new `Scheduler` |
| `Expression#match?(time)` | Check if a Time matches the expression |
| `Expression#next_at(from:)` | Find the next matching Time |
| `Expression#to_s` | Return the original expression string |
| `Scheduler#every(expression, name: nil, &block)` | Register a cron job |
| `Scheduler#job_names` | List registered job names |
| `Scheduler#remove(name)` | Remove a job by name |
| `Scheduler#next_runs(from:)` | Hash of job names to their next scheduled time |
| `Scheduler#start` | Start the scheduler in a background thread |
| `Scheduler#stop` | Stop the scheduler |
| `Scheduler#running?` | Check if the scheduler is running |


## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

[MIT](LICENSE)
