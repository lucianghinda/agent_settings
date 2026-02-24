# frozen_string_literal: true

module AgentSettings
  # The complete result of resolving an agent's config location.
  #
  # AgentConfigPath is the primary return value from {AgentSettings.resolve}
  # and contains all information about where an agent's configuration is
  # located, including:
  #
  # - The effective (active) config location
  # - Global and project-specific locations
  # - All config layers organized by precedence
  # - Environment variable overrides detected
  # - Any warnings (e.g., untrusted project)
  #
  # The effective location is determined by checking in order:
  # 1. Active environment variable overrides (highest precedence)
  # 2. First existing layer in precedence order
  # 3. First layer if none exist
  #
  # @example
  #   result = AgentSettings.resolve(:claude, dir: Dir.pwd)
  #   result.effective.path     #=> "/Users/me/.claude/settings.json"
  #   result.effective.exists?  #=> true
  #   result.global             #=> Location for global config
  #   result.project            #=> Location for project config
  #   result.custom_config?     #=> false (no env override active)
  #
  # @attr agent [Symbol] the agent this config path is for
  # @attr effective [Location, nil] the currently active config location
  # @attr global [Location, nil] the global (user) config location
  # @attr project [Location, nil] the project-level config location
  # @attr layers [Array<Location>] all config locations in precedence order
  # @attr env_overrides [Array<EnvOverride>] detected environment variable overrides
  # @attr warnings [Array<String>] any warnings about the configuration
  AgentConfigPath = Data.define(:agent, :effective, :global, :project, :layers, :env_overrides, :warnings) do
    # Check if a custom config is being used via environment variable.
    #
    # Returns true if any environment variable override is active,
    # meaning the agent is using a config location different from
    # the default file-based locations.
    #
    # @return [Boolean] true if an environment override is active
    #
    # @example
    #   env = { "OPENCODE_CONFIG" => "/custom/config.json" }
    #   result = AgentSettings.resolve(:opencode, dir: Dir.pwd, env: env)
    #   result.custom_config?  #=> true (if /custom/config.json exists)
    def custom_config? = env_overrides.any?(&:active?)
  end
end
