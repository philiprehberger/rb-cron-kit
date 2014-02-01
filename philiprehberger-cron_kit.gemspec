# frozen_string_literal: true

require_relative "lib/philiprehberger/cron_kit/version"

Gem::Specification.new do |spec|
  spec.name          = "philiprehberger-cron_kit"
  spec.version       = Philiprehberger::CronKit::VERSION
  spec.authors       = ["Philip Rehberger"]
  spec.email         = ["me@philiprehberger.com"]

  spec.summary       = "Cron expression parser and scheduler"
  spec.description   = "A zero-dependency Ruby gem for parsing 5-field cron expressions and running " \
                        "an in-process scheduler. Supports wildcards, ranges, steps, and lists."
  spec.homepage      = "https://github.com/philiprehberger/rb-cron-kit"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib}/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  end

  spec.require_paths = ["lib"]
end
