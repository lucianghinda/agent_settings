# frozen_string_literal: true

module AgentSettings
  module Adapters
    # Adapter for Claude Code agent configuration.
    #
    # Claude Code stores configuration in JSON files at various locations:
    #
    # - Global: ~/.claude/settings.json (user-level config)
    # - Project: .claude/settings.json (project-level config)
    # - Local: .claude/settings.local.json (local overrides, not committed)
    # - Managed: /Library/Application Support/ClaudeCode/managed-settings.json (macOS system-level)
    #
    # Precedence (highest to lowest): managed > local > project > global
    #
    # Environment variable CLAUDE_CONFIG_DIR can override the global config location.
    #
    # @example
    #   adapter = Claude.new
    #   layers = adapter.layers(dir: "/work/my_app", env: ENV, trusted: true)
    #   env_overrides = adapter.env_overrides(dir: "/work/my_app", env: ENV, trusted: true)
    class Claude
      # Get all config layers for Claude Code.
      #
      # Returns an array of Location objects representing all possible
      # config file locations, ordered by precedence (highest first).
      # Only one layer will be marked as active (the first existing one).
      #
      # @param dir [String] project directory path
      # @param env [Hash] environment variables hash
      # @param trusted [Boolean] whether the project is trusted (unused for Claude)
      # @return [Array<Location>] config layers in precedence order
      def layers(dir:, env:, trusted:) # rubocop:disable Lint/UnusedMethodArgument
        build_layers(dir, env)
      end

      # Get environment variable overrides for Claude Code.
      #
      # Checks for CLAUDE_CONFIG_DIR environment variable and returns
      # an EnvOverride if it's set. The override is active if the
      # resulting settings.json file exists.
      #
      # @param dir [String] project directory path (unused)
      # @param env [Hash] environment variables hash
      # @param trusted [Boolean] whether the project is trusted (unused)
      # @return [Array<EnvOverride>] detected environment overrides
      def env_overrides(dir:, env:, trusted:) # rubocop:disable Lint/UnusedMethodArgument
        build_env_overrides(env)
      end

      # Get warnings for Claude Code configuration.
      #
      # Claude Code doesn't produce any warnings currently.
      #
      # @return [Array<String>] empty array
      def warnings(*) = []

      private

      # Build the list of config layers.
      #
      # Creates Location objects for each possible config location,
      # ordered by precedence. The managed config (system-level) has
      # highest precedence, followed by local project overrides,
      # then project config, then user global config.
      #
      # @param dir [String] project directory path
      # @param env [Hash] environment variables hash
      # @return [Array<Location>] config layers with active flag set
      def build_layers(dir, env) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength -- builds all layer types in one coherent method
        home = Dir.home
        config_dir = env["CLAUDE_CONFIG_DIR"]

        managed_path = managed_config_path
        global_path = config_dir ? File.join(config_dir, "settings.json") : File.join(home, ".claude", "settings.json")
        project_path = File.join(dir, ".claude", "settings.json")
        local_path = File.join(dir, ".claude", "settings.local.json")

        layers = []

        layers << build_layer(:managed, "system", managed_path) if managed_path
        layers << build_layer(:global, "user", global_path)
        layers << build_layer(:project, "local", local_path)
        layers << build_layer(:project, "file", project_path)

        mark_active(layers)
      end

      # Build environment variable overrides.
      #
      # Checks if CLAUDE_CONFIG_DIR is set and creates an EnvOverride
      # for it. The override's path is the settings.json file within
      # the specified directory.
      #
      # @param env [Hash] environment variables hash
      # @return [Array<EnvOverride>] detected overrides
      def build_env_overrides(env) # rubocop:disable Metrics/MethodLength -- constructs EnvOverride with all required attributes
        overrides = []
        value = env["CLAUDE_CONFIG_DIR"]

        if value
          path = File.join(value, "settings.json")
          overrides << EnvOverride.new(
            agent: :claude,
            name: "CLAUDE_CONFIG_DIR",
            value: value,
            path: path,
            exists: File.exist?(path),
            active: File.exist?(path),
            note: "Config directory override"
          )
        end

        overrides
      end

      # Get the managed (system-level) config path.
      #
      # Managed config is typically set by system administrators and
      # has the highest precedence. Location varies by OS:
      # - macOS: /Library/Application Support/ClaudeCode/managed-settings.json
      # - Linux: /etc/claude-code/managed-settings.json
      #
      # @return [String, nil] the managed config path if it exists, nil otherwise
      def managed_config_path
        case RbConfig::CONFIG["host_os"]
        when /darwin/
          path = "/Library/Application Support/ClaudeCode/managed-settings.json"
          File.exist?(path) ? path : nil
        when /linux/
          path = "/etc/claude-code/managed-settings.json"
          File.exist?(path) ? path : nil
        end
      end

      # Build a Location object for a config layer.
      #
      # @param scope [Symbol] the scope (:global, :project, :managed)
      # @param source [String] where this config comes from
      # @param path [String] the file path
      # @return [Location] a Location object (not yet marked active)
      def build_layer(scope, source, path)
        Location.new(
          agent: :claude,
          scope: scope,
          source: source,
          path: path,
          exists: File.exist?(path),
          active: false,
          note: nil
        )
      end

      # Mark the first existing layer as active.
      #
      # Iterates through layers and marks the first one that exists
      # as active. This implements the precedence rule where the
      # first existing config file wins.
      #
      # @param layers [Array<Location>] config layers
      # @return [Array<Location>] layers with active flag set
      def mark_active(layers)
        found = layers.find(&:exists?)
        layers.map do |layer|
          layer.with(active: layer == found)
        end
      end
    end
  end
end
