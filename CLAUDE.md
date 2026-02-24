# agent_settings

Ruby gem that provides a clean interface to discover config locations for Claude Code, OpenCode, and Codex — including whether each path exists and which path is currently effective based on precedence and overrides.

Read @doc/ruby.md before writing any Ruby code.

## Public API

```ruby
AgentSettings.global(agent, env: ENV, dir: Dir.pwd, trusted: true)
AgentSettings.project(agent, dir:, env: ENV, trusted: true)
AgentSettings.resolve(agent, dir:, env: ENV, trusted: true)
AgentSettings.all(dir:, env: ENV, trusted: true)
```

## File Layout

```
lib/agent_settings.rb
lib/agent_settings/version.rb
lib/agent_settings/location.rb
lib/agent_settings/variable.rb
lib/agent_settings/resolution.rb
lib/agent_settings/resolver.rb
lib/agent_settings/registry.rb
lib/agent_settings/adapters/claude.rb
lib/agent_settings/adapters/opencode.rb
lib/agent_settings/adapters/codex.rb
test/
```

## Core Value Objects

- `Location` — fields: `agent, scope, source, path, exists, active, note`; methods: `exists?`, `active?`
- `Variable` — fields: `agent, name, value, path, exists, active, note`; methods: `exists?`, `active?`
- `Resolution` — fields: `agent, effective, global, project, layers, variables, warnings`; method: `custom_config?`

## Core Classes

- `Resolver` — builds final `Resolution`, picks effective location from precedence layers
- `Registry` — maps agent symbols to adapters
- `Adapters::Claude`, `Adapters::Opencode`, `Adapters::Codex` — each exposes `layers(dir:, env:, trusted:)`, `variables(dir:, env:, trusted:)`, `warnings(dir:, env:, trusted:)`

## Agent Config Rules

### Claude Code
- Global: `~/.claude/settings.json`
- Project: `.claude/settings.json`
- Local project override: `.claude/settings.local.json`
- Managed/system: `/Library/Application Support/ClaudeCode/managed-settings.json` (macOS), `/etc/claude-code/managed-settings.json` (Linux)
- Env override: `CLAUDE_CONFIG_DIR`
- Precedence (high→low): managed > CLI > local project > project > user

### OpenCode
- Global: `~/.config/opencode/opencode.json`
- Project: `opencode.json` (discovered from dir toward project root)
- Env overrides: `OPENCODE_CONFIG`, `OPENCODE_CONFIG_DIR`, `OPENCODE_CONFIG_CONTENT`

### Codex
- User: `~/.codex/config.toml`
- Project: `.codex/config.toml` (trusted projects only)
- System: `/etc/codex/config.toml`
- Env base override: `CODEX_HOME`

## Ruby Conventions

Use Ruby 3.x features:
- `Data` objects for immutable value objects (`Location`, `Variable`, `Resolution`)
- Pattern matching (`case/in`, `=>`)
- Endless methods for simple one-liners
- Keyword arguments throughout
- Safe navigation operator (`&.`)

Design principles (Sandi Metz / OOD):
- Tiny public surface — expose only what callers need
- Intention-revealing names — reflect domain, not implementation
- Single responsibility — one sentence description per class, no "and/or"
- Tell, don't ask — send messages, avoid train wrecks
- Depend on behavior (duck types), not class names
- Composed methods — each method does one thing at one level of abstraction

Naming rules:
- Boolean methods end with `?` (e.g., `exists?`, `active?`, `custom_config?`)
- Positive names (`active` not `not_deleted`)
- Variables named for their role, not their type
- No design pattern names in class names

## Testing (Minitest)

- Test public interfaces only; test private methods indirectly
- Cover: global/project resolution per agent, override variable detection, effective path precedence, `exists?` true/false, trusted vs untrusted Codex behavior

## Dependencies

- `zeitwerk` runtime dependency; use `Zeitwerk::Loader.for_gem` in entrypoint
