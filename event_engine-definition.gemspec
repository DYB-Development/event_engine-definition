# frozen_string_literal: true

require_relative "lib/event_engine/definition/version"

Gem::Specification.new do |spec|
  spec.name = "event_engine-definition"
  spec.version = EventEngine::Definition::VERSION
  spec.authors = ["tylercschneider"]
  spec.email = ["tylercschneider@gmail.com"]

  spec.summary = "Plain-Ruby event-definition contract for the EventEngine pipeline"
  spec.description = "The plain-Ruby foundation of the EventEngine pipeline: the EventDefinition DSL and the shared schema-contract value objects, with no Rails dependency. Lightweight domain-pack gems depend on this contract instead of the full dispatch, registry, and Rails-engine machinery that lives in event_engine."
  spec.homepage = "https://eventengine.co"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  repo_url = "https://github.com/DYB-Development/event_engine-definition"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = repo_url
  spec.metadata["bug_tracker_uri"] = "#{repo_url}/issues"
  spec.metadata["documentation_uri"] = "#{repo_url}#readme"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
