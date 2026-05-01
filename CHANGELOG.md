# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - 2026-05-01

### Added
- `Scheduler#run_now(name)` — manually trigger a registered job by name. Reuses the standard execution path (timeout + overlap-skip), runs synchronously, returns the block's value, and raises `KeyError` for unknown names or `Timeout::Error` when the job exceeds its `timeout:`. Returns `nil` when skipped due to `overlap: false`.

## [0.6.0] - 2026-04-16

### Added
- `Expression#matches_any?(times)` returns true if any `Time` in the given enumerable matches the expression, short-circuiting on the first match

## [0.5.1] - 2026-04-15

### Fixed
- Correct homepage URL in gemspec to use repo-style slug (`philiprehberger-cron-kit`)

## [0.5.0] - 2026-04-12

### Added
- `Scheduler#every` accepts `overlap: false` to skip a job tick when the previous run is still active
- Bug report template now requires Ruby version and gem version fields
- Feature request template now includes alternatives considered field

### Fixed
- README Usage section structure: first example no longer wrapped in a subsection header
- Bug report template placeholder for reproduction steps
- Feature request template placeholder for proposed API

## [0.4.2] - 2026-04-08

### Changed
- Align gemspec summary with README description.

## [0.4.1] - 2026-04-07

### Added
- `Philiprehberger::CronKit.valid?` and `Expression.valid?` predicates for non-raising expression validation

## [0.4.0] - 2026-04-05

### Added
- `Scheduler#on_error` callback for handling job failures
- `Scheduler#running_jobs` method to inspect active job count
- Graceful timeout: raises `Timeout::Error` before hard-killing timed-out jobs

## [0.3.10] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.3.9] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.3.8] - 2026-03-26

### Changed
- Add Sponsor badge to README
- Fix License section format
- Sync gemspec summary with README


## [0.3.7] - 2026-03-24

### Changed
- Expand test coverage to 70+ examples covering edge cases and error paths

## [0.3.6] - 2026-03-24

### Fixed
- Align README one-liner with gemspec summary

## [0.3.5] - 2026-03-23

### Fixed
- Standardize README/CHANGELOG to match template guide

## [0.3.4] - 2026-03-22

### Changed
- Update rubocop configuration for Windows compatibility

## [0.3.3] - 2026-03-20

### Fixed
- Standardize Installation section in README
- Fix README description format (single sentence, no trailing period)
- Fix CHANGELOG header wording

## [0.3.2] - 2026-03-20

### Fixed
- Fix Gem Version badge URL in README

## [0.3.1] - 2026-03-18

### Changed
- Fix RuboCop Style/StringLiterals violations in gemspec

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

## [0.2.1] - 2026-03-17

### Added
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
