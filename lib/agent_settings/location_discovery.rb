# frozen_string_literal: true

module AgentSettings
  # Internal module for discovering agent config locations.
  #
  # LocationDiscovery contains the core logic for finding and resolving
  # where agent configuration files are located. It uses adapters (one per
  # agent) to handle agent-specific rules, then applies common precedence
  # logic to determine the effective configuration.
  #
  # This module is used internally by the {AgentSettings} public API methods.
  # You typically don't need to call it directly.
  #
  # @api private
  module LocationDiscovery
    module_function

    # Find the global config location for an agent.
    #
    # Queries the appropriate adapter and extracts the global-scoped
    # location from the layers.
    #
    # @param agent [Symbol] the agent identifier
    # @param env [Hash] environment variables
    # @param dir [String] project directory
    # @param trusted [Boolean] whether project is trusted
    # @return [Location, nil] the global location, or nil
    def global(agent, env:, dir:, trusted:)
      adapter = Registry.adapter(agent)
      layers = adapter.layers(dir: dir, env: env, trusted: trusted)
      layers.find { |l| l.scope == :global }
    end

    # Find the project config location for an agent.
    #
    # Queries the appropriate adapter and extracts the project-scoped
    # location from the layers. Note that some agents (like Codex) may
    # not return a project location for untrusted projects.
    #
    # @param agent [Symbol] the agent identifier
    # @param dir [String] project directory
    # @param env [Hash] environment variables
    # @param trusted [Boolean] whether project is trusted
    # @return [Location, nil] the project location, or nil
    def project(agent, dir:, env:, trusted:)
      adapter = Registry.adapter(agent)
      layers = adapter.layers(dir: dir, env: env, trusted: trusted)
      layers.find { |l| l.scope == :project }
    end

    # Resolve complete config path information for an agent.
    #
    # This is the main discovery method. It:
    # 1. Gets the appropriate adapter for the agent
    # 2. Retrieves all config layers from the adapter
    # 3. Retrieves any environment variable overrides
    # 4. Retrieves any warnings
    # 5. Determines the effective location based on precedence
    # 6. Builds and returns an AgentConfigPath with all information
    #
    # @param agent [Symbol] the agent identifier
    # @param dir [String] project directory
    # @param env [Hash] environment variables
    # @param trusted [Boolean] whether project is trusted
    # @return [AgentConfigPath] complete config path information
    def resolve(agent, dir:, env:, trusted:) # rubocop:disable Metrics/MethodLength -- orchestrates adapter calls and builds complete AgentConfigPath
      adapter = Registry.adapter(agent)
      layers = adapter.layers(dir: dir, env: env, trusted: trusted)
      env_overrides = adapter.env_overrides(dir: dir, env: env, trusted: trusted)
      warnings = adapter.warnings(dir: dir, env: env, trusted: trusted)

      effective = find_effective(layers, env_overrides)
      global = layers.find { |l| l.scope == :global }
      project = layers.find { |l| l.scope == :project }

      AgentConfigPath.new(
        agent: agent,
        effective: effective,
        global: global,
        project: project,
        layers: layers,
        env_overrides: env_overrides,
        warnings: warnings
      )
    end

    # Resolve config paths for all supported agents.
    #
    # Iterates through all known agents and resolves each one,
    # returning a hash mapping agent symbols to AgentConfigPath objects.
    #
    # @param dir [String] project directory
    # @param env [Hash] environment variables
    # @param trusted [Boolean] whether project is trusted
    # @return [Hash{Symbol => AgentConfigPath}] map of agent to config path
    def all(dir:, env:, trusted:)
      Registry::AGENTS.to_h do |agent|
        [agent, resolve(agent, dir: dir, env: env, trusted: trusted)]
      end
    end

    # Determine the effective config location.
    #
    # The effective location is determined by precedence:
    # 1. If an environment override is active, convert it to a Location
    # 2. Otherwise, use the first existing layer
    # 3. If no layers exist, use the first layer (even though it doesn't exist)
    #
    # @param layers [Array<Location>] config layers in precedence order
    # @param env_overrides [Array<EnvOverride>] environment variable overrides
    # @return [Location, nil] the effective location
    def find_effective(layers, env_overrides)
      active_override = env_overrides.find(&:active?)
      return active_override.to_location if active_override

      layers.find(&:active?) || layers.first
    end
  end
end
