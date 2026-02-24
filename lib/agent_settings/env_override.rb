# frozen_string_literal: true

module AgentSettings
  # Represents an environment variable that overrides config location.
  #
  # Agents can use environment variables to override their default config
  # locations. EnvOverride captures information about these variables,
  # including their name, value, the resulting config path, and whether
  # the override is active (i.e., the target file exists).
  #
  # Supported environment variables by agent:
  # - Claude: CLAUDE_CONFIG_DIR
  # - OpenCode: OPENCODE_CONFIG, OPENCODE_CONFIG_DIR, OPENCODE_CONFIG_CONTENT
  # - Codex: CODEX_HOME
  #
  # @example
  #   override = EnvOverride.new(
  #     agent: :claude,
  #     name: 'CLAUDE_CONFIG_DIR',
  #     value: '/custom/config',
  #     path: '/custom/config/settings.json',
  #     exists: true,
  #     active: true,
  #     note: 'Config directory override'
  #   )
  #   override.active?  #=> true
  #
  # @attr agent [Symbol] the agent this override applies to
  # @attr name [String] the environment variable name (e.g., 'CLAUDE_CONFIG_DIR')
  # @attr value [String] the value of the environment variable
  # @attr path [String] the resulting config file path
  # @attr exists [Boolean] whether the config file exists at this path
  # @attr active [Boolean] whether this override is in effect (file exists)
  # @attr note [String] description of what this override does
  EnvOverride = Data.define(:agent, :name, :value, :path, :exists, :active, :note) do
    # @return [Boolean] whether the config file exists at this path
    def exists? = exists

    # @return [Boolean] whether this override is in effect
    def active? = active

    # Convert this override to a Location object.
    #
    # When an environment override is active, it becomes the effective
    # config location. This method converts the override to a Location
    # with scope :env.
    #
    # @return [Location] a Location representing this override
    def to_location
      Location.new(
        agent: agent,
        scope: :env,
        source: name,
        path: path,
        exists: exists,
        active: active,
        note: note
      )
    end
  end
end
