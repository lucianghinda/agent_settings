# Agent Settings - Ruby Gem

Ruby gem that provides a clean interface to discover config locations for Claude Code, OpenCode, and Codex — including whether each path exists and which path is currently effective based on precedence and overrides.

Read @doc/ruby.md before writing any Ruby code.

## Build / Lint / Test Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rake test

# Run a single test file
bundle exec ruby -Ilib:test test/agent_settings/resolver_test.rb

# Run a single test by name
bundle exec ruby -Ilib:test test/agent_settings/resolver_test.rb --name test_global_resolution

# Run tests with verbose output
bundle exec rake test TESTOPTS="--verbose"

# Lint with RuboCop (if configured)
bundle exec rubocop

# Lint and auto-correct
bundle exec rubocop -a

# Build the gem
bundle exec rake build

# Install the gem locally
bundle exec rake install

# Run the console for experimentation
bundle exec console
```

## Project Structure

```
lib/agent_settings.rb           # Entry point with Zeitwerk loader
lib/agent_settings/version.rb   # Version constant
lib/agent_settings/location.rb  # Location value object
lib/agent_settings/env_override.rb  # EnvOverride value object
lib/agent_settings/agent_config_path.rb # AgentConfigPath value object
lib/agent_settings/location_discovery.rb  # Core discovery logic
lib/agent_settings/registry.rb  # Agent-to-adapter mapping
lib/agent_settings/adapters/    # Per-agent adapters
  claude.rb
  opencode.rb
  codex.rb
test/                           # Minitest tests
```

## Public API

```ruby
AgentSettings.global(agent, env: ENV, dir: Dir.pwd, trusted: true)
AgentSettings.project(agent, dir:, env: ENV, trusted: true)
AgentSettings.resolve(agent, dir:, env: ENV, trusted: true)
AgentSettings.all(dir:, env: ENV, trusted: true)
```

Supported agents: `:claude`, `:opencode`, `:codex`

## Code Style Guidelines

### Ruby 3.x Features

Use modern Ruby features throughout:

```ruby
# Data objects for immutable value objects
Location = Data.define(:agent, :scope, :path, :exists, :active) do
  def exists? = exists
  def active? = active
end

# Pattern matching
case agent
in :claude then ClaudeAdapter.new
in :opencode then OpencodeAdapter.new
in :codex then CodexAdapter.new
end

# Endless methods for simple one-liners
def global = layers.find { |l| l.scope == :global }
def custom_config? = variables.any?(&:active?)

# Keyword arguments throughout
def resolve(agent, dir:, env: ENV, trusted: true)

# Safe navigation operator
path = env["CLAUDE_CONFIG_DIR"]&.then { |dir| File.join(dir, "settings.json") }
```

### Naming Conventions

- **Boolean methods** end with `?`: `exists?`, `active?`, `custom_config?`
- **Positive names**: use `active` not `not_deleted`
- **Role-based naming**: name variables after their role, not type
- **No pattern names in classes**: avoid `ResolverFactory`, `LocationDecorator`
- **Domain language**: reflect the business domain in names

### Method Design

- **Composed methods**: each method does one thing at one abstraction level
- **Intention-revealing selectors**: name after what, not how
- **Keyword arguments**: always prefer over positional arguments
- **Tiny public surface**: expose only what callers need

### Class Design

- **Single responsibility**: one sentence description, no "and/or"
- **Cohesion**: everything in a class shares one idea
- **Composition over inheritance**: prefer composition
- **Law of Demeter**: only talk to immediate neighbors
- **Tell, don't ask**: send messages, avoid train wrecks

### Value Objects

Use `Data.define` for immutable value objects:

```ruby
module AgentSettings
  Location = Data.define(:agent, :scope, :source, :path, :exists, :active, :note) do
    def exists? = exists
    def active? = active
  end

  EnvOverride = Data.define(:agent, :name, :value, :path, :exists, :active, :note) do
    def exists? = exists
    def active? = active
  end

  AgentConfigPath = Data.define(:agent, :effective, :global, :project, :layers, :env_overrides, :warnings) do
    def custom_config? = env_overrides.any?(&:active?)
  end
end
```

### Error Handling

Use custom error classes for domain errors:

```ruby
module AgentSettings
  class Error < StandardError; end
  class UnknownAgentError < Error; end
  class InvalidConfigError < Error; end
end

# Raise with clear messages
raise UnknownAgentError, "Unknown agent: #{agent}. Supported: #{Registry::AGENTS.join(', ')}"
```

### Adapter Protocol

Each adapter must implement:

```ruby
class SomeAdapter
  # Returns array of Location objects, ordered by precedence (highest first)
  def layers(dir:, env:, trusted:) = [...]

  # Returns array of EnvOverride objects for env overrides
  def env_overrides(dir:, env:, trusted:) = [...]

  # Returns array of warning strings
  def warnings(dir:, env:, trusted:) = []
end
```

## Agent Config Rules

### Claude Code
- Global: `~/.claude/settings.json`
- Project: `.claude/settings.json`
- Local override: `.claude/settings.local.json`
- Managed: `/Library/Application Support/ClaudeCode/managed-settings.json` (macOS)
- Env override: `CLAUDE_CONFIG_DIR`
- Precedence: managed > CLI > local project > project > user

### OpenCode
- Global: `~/.config/opencode/opencode.json`
- Project: `opencode.json` (discovered upward from dir)
- Env overrides: `OPENCODE_CONFIG`, `OPENCODE_CONFIG_DIR`, `OPENCODE_CONFIG_CONTENT`

### Codex
- User: `~/.codex/config.toml`
- Project: `.codex/config.toml` (trusted projects only)
- System: `/etc/codex/config.toml`
- Env override: `CODEX_HOME`
- Trust caveat: project config ignored for untrusted projects

## Testing Strategy

- **Test public interfaces only**: test what callers see
- **Test private methods indirectly**: through public API
- **Cover these scenarios**:
  - Global/project resolution per agent
  - Override variable detection and activation
  - Effective path precedence
  - `exists?` true/false for paths
  - Trusted vs untrusted Codex behavior

```ruby
class LocationDiscoveryTest < Minitest::Test
  def test_global_resolution_for_claude
    result = AgentSettings.global(:claude)
    assert_equal :global, result.scope
    assert_predicate result, :exists?
  end

  def test_project_config_ignored_for_untrusted_codex
    result = AgentSettings.resolve(:codex, dir: "/untrusted/repo", trusted: false)
    assert_nil result.project
  end
end
```

## Dependencies

- **Runtime**: `zeitwerk` (autoloading)
- **Development**: `minitest`, `rake`, `rubocop` (optional)

Use Zeitwerk at entry point:

```ruby
# lib/agent_settings.rb
require "zeitwerk"
Zeitwerk::Loader.for_gem.setup
```

## Design Principles

1. **Messaging over objects**: focus on messages passing between objects
2. **Behavior over data**: depend on what objects do, not what they are
3. **Duck typing**: type is defined by behavior, not class
4. **Dependency injection**: pass collaborators, don't hard-code class names
5. **Late binding**: allow objects to hide internal state-process
