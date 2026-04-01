# frozen_string_literal: true

require_relative 'lib/philiprehberger/cron_kit/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-cron_kit'
  spec.version = Philiprehberger::CronKit::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']

  spec.summary = 'Cron expression parser and scheduler for Ruby'
  spec.description = 'A zero-dependency Ruby gem for parsing 5-field cron expressions and running ' \
                     'an in-process scheduler. Supports wildcards, ranges, steps, and lists.'
  spec.homepage      = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-cron_kit'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/philiprehberger/rb-cron-kit'
  spec.metadata['changelog_uri']         = 'https://github.com/philiprehberger/rb-cron-kit/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/philiprehberger/rb-cron-kit/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
