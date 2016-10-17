# Changelog

All notable changes to this project will be documented in this file.

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

[0.2.0]: https://github.com/philiprehberger/rb-cron-kit/releases/tag/v0.2.0
[0.1.0]: https://github.com/philiprehberger/rb-cron-kit/releases/tag/v0.1.0
