# Changelog

## 0.3.1

- Fix RuboCop Style/StringLiterals violations in gemspec

All notable changes to this project will be documented in this file.

## [0.3.2] - 2026-03-20

### Fixed
- Fix Gem Version badge URL in README

## [0.3.0] - 2026-03-17

### Added

- Timezone support via `timezone:` option on `parse` and `Expression.new`
- `Expression#next_runs(count:, from:)` to preview the next N execution times
- `Expression#previous_run(from:)` to find the most recent past match
- Job timeout via `timeout:` option on `Scheduler#every` — kills jobs exceeding the limit
- Non-standard cron aliases: `@hourly`, `@daily`, `@weekly`, `@monthly`, `@yearly`, `@annually`
- `Aliases` module for alias expansion
- `Timezone` module for offset resolution (stdlib only)
- `Parser` module extracted from `Expression` for field parsing logic

## 0.2.1

- Add License badge to README
- Add bug_tracker_uri to gemspec
- Add Development section to README
- Add Requirements section to README

## [0.2.0] - 2026-03-12

### Added

- Named jobs via `name:` keyword on `every`
- `job_names` method to list registered job names
- `remove(name)` method to unregister jobs
- `next_runs(from:)` method for inspecting upcoming scheduled times
- Concurrent job execution with per-job error isolation

## [0.1.0] - 2026-03-10

### Added

- Cron expression parser supporting 5-field expressions (minute, hour, day-of-month, month, day-of-week)
- Support for wildcards (`*`), specific values, ranges (`1-5`), steps (`*/5`), and lists (`1,3,5`)
- `Expression#match?` to check if a Time matches a cron expression
- `Expression#next_at` to find the next matching Time from a given start
- `Scheduler` class for running cron jobs in a background thread
- `Philiprehberger::CronKit.parse` convenience method
- `Philiprehberger::CronKit.new` convenience method for creating a Scheduler

[0.3.0]: https://github.com/philiprehberger/rb-cron-kit/releases/tag/v0.3.0
[0.2.0]: https://github.com/philiprehberger/rb-cron-kit/releases/tag/v0.2.0
[0.1.0]: https://github.com/philiprehberger/rb-cron-kit/releases/tag/v0.1.0
