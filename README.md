# agent_settings

Discover config locations for Claude Code, OpenCode, and Codex

If you are an LLM/AI Agent read [./llm.txt](llm.txt) in this repository. 

## Installation

Add this line to your application's **Gemfile**:

```ruby
gem "agent_settings"
```

And run:

```bash
bundle install
```

Or install it directly:

```bash
gem install agent_settings
```

## Quick Start

Get the effective config for an agent:

```ruby
require "agent_settings"

result = AgentSettings.resolve(:claude, dir: Dir.pwd)
puts result.effective.path
```

## Usage

### Get Global Config

Retrieve the global config location for an agent:

```ruby
location = AgentSettings.global(:claude)
location.path    # => "/Users/me/.claude/settings.json"
location.exists? # => true
```

### Get Project Config

Retrieve the project-level config location:

```ruby
location = AgentSettings.project(:codex, dir: "/work/my_app")
location.path    # => "/work/my_app/.codex/config.toml"
location.exists? # => false
```

### Resolve Effective Config

Get the active config with full details:

```ruby
result = AgentSettings.resolve(:opencode, dir: "/work/my_app")

result.effective.path   # the active config path
result.global           # global location
result.project          # project location
result.layers           # all config layers by precedence
result.env_overrides    # environment variable overrides
result.warnings         # any warnings
result.custom_config?   # true if env override is active
```

### Resolve All Agents

Get config paths for all supported agents:

```ruby
results = AgentSettings.all(dir: "/work/my_app")

results.each do |agent, config_path|
  puts "#{agent}: #{config_path.effective.path}"
end
```

### Detect Environment Overrides

Check if environment variables override config paths:

```ruby
result = AgentSettings.resolve(:opencode, dir: Dir.pwd, env: ENV)

result.env_overrides.each do |override|
  puts "#{override.name}=#{override.value}"
  puts "  active: #{override.active?}"
end
```

### Handle Untrusted Projects

Codex ignores project config for untrusted projects:

```ruby
# trusted (default) - includes project config
result = AgentSettings.resolve(:codex, dir: dir, trusted: true)

# untrusted - excludes project config
result = AgentSettings.resolve(:codex, dir: dir, trusted: false)
result.warnings # => ["Project config ignored for untrusted project"]
```

## Supported Agents

| Agent | Global Config | Project Config |
|-------|---------------|----------------|
| Claude | `~/.claude/settings.json` | `.claude/settings.json` |
| OpenCode | `~/.config/opencode/opencode.json` | `opencode.json` |
| Codex | `~/.codex/config.toml` | `.codex/config.toml` |

## Options

All methods accept these keyword arguments:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `agent` | Symbol | required | `:claude`, `:opencode`, or `:codex` |
| `dir` | String | `Dir.pwd` | Project directory path |
| `env` | Hash | `ENV` | Environment variables hash |
| `trusted` | Boolean | `true` | Trust project for Codex |

## Value Objects

### Location

Represents a config file location:

```ruby
location.agent    # => :claude
location.scope    # => :global or :project
location.path     # => "/Users/me/.claude/settings.json"
location.exists?  # => true
location.active?  # => true
```

### EnvOverride

Represents an environment variable override:

```ruby
override.name     # => "CLAUDE_CONFIG_DIR"
override.value    # => "/custom/path"
override.path     # => "/custom/path/settings.json"
override.active?  # => true
```

### AgentConfigPath

The result of resolving an agent's config:

```ruby
config.effective      # => Location (highest precedence)
config.global         # => Location or nil
config.project        # => Location or nil
config.layers         # => Array of Location
config.env_overrides  # => Array of EnvOverride
config.warnings       # => Array of String
config.custom_config? # => true if env override active
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License
The gem is available as open source under the terms of the Apache 2.0 License.
