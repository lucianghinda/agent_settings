# frozen_string_literal: true

require_relative "lib/agent_settings/version"

Gem::Specification.new do |spec|
  spec.name = "agent_settings"
  spec.version = AgentSettings::VERSION
  spec.authors = ["Lucian Ghinda"]
  spec.email = ["lucian@ghinda.com"]

  spec.summary = "Discover config locations for Claude Code, OpenCode, and Codex"
  spec.description = "Clean interface to discover configuration file locations for" \
                     "AI coding assistants (Claude Code, OpenCode, Codex). " \
                     "Shows global and project config paths, handles environment variable overrides, " \
                     "and determines which config is effective based on precedence rules."
  spec.homepage = "https://github.com/ghinda/agent_settings"
  spec.license = "Apache 2.0 License"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "zeitwerk"
end
