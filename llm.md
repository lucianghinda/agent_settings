# Module AgentSettings <a id="module-AgentSettings"></a>

Discover config locations for Claude Code, OpenCode, and Codex.

This gem provides a clean interface to find where agent configuration files
are located, whether they exist, and which one is currently effective based on
precedence rules and environment variable overrides.

## Trusted vs Untrusted Projects

The `trusted` parameter controls whether project-level config is included in
resolution. This is a security feature for Codex:

*   **Trusted projects** (`trusted: true`): Project config is included in
    resolution. Use this for projects you own or have reviewed.
*   **Untrusted projects** (`trusted: false`): Project config is ignored for
    Codex. This prevents untrusted code repositories from injecting malicious
    configuration. A warning is added if a <code>.codex/config.toml</code>
    file exists but is ignored.

Claude Code and OpenCode do not use the trust model - their project configs
are always included regardless of the `trusted` parameter.

**@example Get global config location**
```ruby
location = AgentSettings.global(:claude)
location.path   #=> "/Users/me/.claude/settings.json"
location.exists? #=> true
```

**@example Resolve effective config with all details**
```ruby
result = AgentSettings.resolve(:opencode, dir: "/work/my_app")
result.effective.path   #=> the active config path
result.custom_config?   #=> true if env override is active
```

**@example Resolve all agents at once**
```ruby
results = AgentSettings.all(dir: Dir.pwd)
results.each do |agent, config_path|
  puts "#{agent}: #{config_path.effective.path}"
end
```

**@example Untrusted project (Codex ignores project config)**
```ruby
result = AgentSettings.resolve(:codex, dir: "/untrusted/repo", trusted: false)
result.project   #=> nil (ignored for security)
result.warnings  #=> ["Project config ignored for untrusted project"]
```

## Constants
### `VERSION` <a id="constant-VERSION"></a> <a id="VERSION-constant"></a>
Current gem version.

## Public Class Methods
### `all(dir:, env: = ENV, trusted: = true)` <a id="method-c-all"></a> <a id="all-class_method"></a>
Resolve config paths for all supported agents.

Returns a hash mapping each agent symbol to its AgentConfigPath result. Useful
for getting an overview of all agent configurations at once.
- **@param** `dir` [String] project directory path (required)
- **@param** `env` [Hash] environment variables hash (default: ENV)
- **@param** `trusted` [Boolean] whether the project is trusted (default: true)
- **@return** [Hash{Symbol => AgentConfigPath}] map of agent to config path

**@example**
```ruby
results = AgentSettings.all(dir: "/work/my_app")
results.each do |agent, config_path|
  puts "#{agent}: #{config_path.effective.path}"
  puts "  exists: #{config_path.effective.exists?}"
end
```

### `global(agent, env: = ENV, dir: = Dir.pwd, trusted: = true)` <a id="method-c-global"></a> <a id="global-class_method"></a>
Get the global config location for an agent.

The global config is typically stored in the user's home directory and applies
across all projects.
- **@param** `agent` [Symbol] the agent identifier (:claude, :opencode, :codex)
- **@param** `env` [Hash] environment variables hash (default: ENV)
- **@param** `dir` [String] project directory path (default: Dir.pwd)
- **@param** `trusted` [Boolean] whether the project is trusted (default: true)
- **@return** [Location, nil] the global config location, or nil if not found

**@example**
```ruby
location = AgentSettings.global(:claude)
location.path   #=> "/Users/me/.claude/settings.json"
location.exists? #=> true
```

### `project(agent, dir:, env: = ENV, trusted: = true)` <a id="method-c-project"></a> <a id="project-class_method"></a>
Get the project-level config location for an agent.

Project configs are stored within the project directory and apply only to that
specific project.

Note: For Codex, project config is ignored when `trusted: false`. This is a
security measure to prevent untrusted repositories from injecting malicious
configuration. In this case, returns nil and a warning is added to the resolve
result.
- **@param** `agent` [Symbol] the agent identifier (:claude, :opencode, :codex)
- **@param** `dir` [String] project directory path (required)
- **@param** `env` [Hash] environment variables hash (default: ENV)
- **@param** `trusted` [Boolean] whether the project is trusted (default: true)
- **@return** [Location, nil] the project config location, or nil if not applicable

**@example**
```ruby
location = AgentSettings.project(:codex, dir: "/work/my_app")
location.path   #=> "/work/my_app/.codex/config.toml"
location.exists? #=> false
```

### `resolve(agent, dir:, env: = ENV, trusted: = true)` <a id="method-c-resolve"></a> <a id="resolve-class_method"></a>
Resolve the complete config path information for an agent.

This is the primary method for discovering all config-related information for
an agent. It returns an AgentConfigPath object containing the effective config
location, global and project locations, all layers by precedence, environment
variable overrides, and any warnings.

The effective location is determined by:
1.  Active environment variable overrides (highest precedence)
2.  First existing layer in precedence order
3.  First layer if none exist
- **@param** `agent` [Symbol] the agent identifier (:claude, :opencode, :codex)
- **@param** `dir` [String] project directory path (required)
- **@param** `env` [Hash] environment variables hash (default: ENV)
- **@param** `trusted` [Boolean] whether the project is trusted (default: true)
- **@return** [AgentConfigPath] complete config path information

**@example Basic usage**
```ruby
result = AgentSettings.resolve(:claude, dir: Dir.pwd)
result.effective.path   #=> the active config path
result.effective.exists? #=> whether the config file exists
result.custom_config?   #=> true if env override is active
```

**@example With environment overrides**
```ruby
env = { "OPENCODE_CONFIG" => "/custom/config.json" }
result = AgentSettings.resolve(:opencode, dir: Dir.pwd, env: env)
result.env_overrides.first.name   #=> "OPENCODE_CONFIG"
result.env_overrides.first.active? #=> true (if file exists)
```

# Documentation

- [doc/AgentSettings/Adapters/Claude.md](doc/AgentSettings/Adapters/Claude.md)
- [doc/AgentSettings/Adapters/Codex.md](doc/AgentSettings/Adapters/Codex.md)
- [doc/AgentSettings/Adapters/Opencode.md](doc/AgentSettings/Adapters/Opencode.md)
- [doc/AgentSettings/Adapters.md](doc/AgentSettings/Adapters.md)
- [doc/AgentSettings/AgentConfigPath.md](doc/AgentSettings/AgentConfigPath.md)
- [doc/AgentSettings/EnvOverride.md](doc/AgentSettings/EnvOverride.md)
- [doc/AgentSettings/Error.md](doc/AgentSettings/Error.md)
- [doc/AgentSettings/Location.md](doc/AgentSettings/Location.md)
- [doc/AgentSettings/LocationDiscovery.md](doc/AgentSettings/LocationDiscovery.md)
- [doc/AgentSettings/Registry.md](doc/AgentSettings/Registry.md)
- [doc/AgentSettings/UnknownAgentError.md](doc/AgentSettings/UnknownAgentError.md)
- [ruby.md](ruby.md)
