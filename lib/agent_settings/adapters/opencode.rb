# frozen_string_literal: true

module AgentSettings
  module Adapters
    # Adapter for OpenCode agent configuration.
    #
    # OpenCode stores configuration in JSON files:
    #
    # - Global: ~/.config/opencode/opencode.json (user-level config)
    # - Project: opencode.json (discovered by walking up from project directory)
    #
    # OpenCode supports multiple environment variable overrides:
    # - OPENCODE_CONFIG: Direct path to config file
    # - OPENCODE_CONFIG_DIR: Directory containing opencode.json
    # - OPENCODE_CONFIG_CONTENT: Inline JSON config content
    #
    # The project config uses discovery - it walks up from the provided
    # directory looking for opencode.json, similar to how git finds .git.
    #
    # @example
    #   adapter = Opencode.new
    #   layers = adapter.layers(dir: "/work/my_app", env: ENV, trusted: true)
    #   env_overrides = adapter.env_overrides(dir: "/work/my_app", env: ENV, trusted: true)
    class Opencode
      # Get all config layers for OpenCode.
      #
      # Returns an array of Location objects for global and project
      # configs. Project config is discovered by walking up the directory
      # tree from the provided dir.
      #
      # @param dir [String] project directory path (starting point for discovery)
      # @param env [Hash] environment variables hash (unused for layers)
      # @param trusted [Boolean] whether the project is trusted (unused)
      # @return [Array<Location>] config layers in precedence order
      def layers(dir:, env:, trusted:) # rubocop:disable Lint/UnusedMethodArgument
        build_layers(dir)
      end

      # Get environment variable overrides for OpenCode.
      #
      # Checks for three environment variables:
      # - OPENCODE_CONFIG: Path to config file (active if file exists)
      # - OPENCODE_CONFIG_DIR: Directory containing opencode.json
      # - OPENCODE_CONFIG_CONTENT: Inline JSON (always active if set)
      #
      # @param dir [String] project directory path (unused)
      # @param env [Hash] environment variables hash
      # @param trusted [Boolean] whether the project is trusted (unused)
      # @return [Array<EnvOverride>] detected environment overrides
      def env_overrides(dir:, env:, trusted:) # rubocop:disable Lint/UnusedMethodArgument
        build_env_overrides(env)
      end

      # Get warnings for OpenCode configuration.
      #
      # OpenCode doesn't produce any warnings currently.
      #
      # @return [Array<String>] empty array
      def warnings(*) = []

      private

      # Build the list of config layers.
      #
      # Creates Location objects for global and project configs.
      # Project config is discovered by walking up the directory tree.
      #
      # @param dir [String] project directory path
      # @return [Array<Location>] config layers with active flag set
      def build_layers(dir)
        home = Dir.home
        global_path = File.join(home, ".config", "opencode", "opencode.json")
        project_path = discover_project_config(dir)

        layers = []
        layers << build_layer(:global, "user", global_path)
        layers << build_layer(:project, "file", project_path) if project_path

        mark_active(layers)
      end

      # Discover project config by walking up the directory tree.
      #
      # OpenCode project config is named opencode.json (no leading dot).
      # This method walks up from the provided directory looking for it,
      # similar to how git finds .git directories.
      #
      # @param dir [String] starting directory
      # @return [String] path to opencode.json (existing or default)
      def discover_project_config(dir)
        current = File.expand_path(dir)
        root = File.expand_path("/")

        while current != root
          path = File.join(current, "opencode.json")
          return path if File.exist?(path)

          current = File.dirname(current)
        end

        File.join(dir, "opencode.json")
      end

      # Build environment variable overrides.
      #
      # Checks all three OpenCode environment variables and creates
      # EnvOverride objects for any that are set. OPENCODE_CONFIG_CONTENT
      # is always active if set (it's inline content, not a file path).
      #
      # @param env [Hash] environment variables hash
      # @return [Array<EnvOverride>] detected overrides
      def build_env_overrides(env) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength -- handles three different env vars with full attribute construction
        overrides = []

        if (value = env["OPENCODE_CONFIG"])
          overrides << EnvOverride.new(
            agent: :opencode,
            name: "OPENCODE_CONFIG",
            value: value,
            path: value,
            exists: File.exist?(value),
            active: File.exist?(value),
            note: "Config file override"
          )
        end

        if (value = env["OPENCODE_CONFIG_DIR"])
          path = File.join(value, "opencode.json")
          overrides << EnvOverride.new(
            agent: :opencode,
            name: "OPENCODE_CONFIG_DIR",
            value: value,
            path: path,
            exists: File.exist?(path),
            active: File.exist?(path),
            note: "Config directory override"
          )
        end

        if (value = env["OPENCODE_CONFIG_CONTENT"])
          overrides << EnvOverride.new(
            agent: :opencode,
            name: "OPENCODE_CONFIG_CONTENT",
            value: value[0, 50] + (value.length > 50 ? "..." : ""),
            path: "(inline)",
            exists: true,
            active: true,
            note: "Inline config content"
          )
        end

        overrides
      end

      # Build a Location object for a config layer.
      #
      # @param scope [Symbol] the scope (:global, :project)
      # @param source [String] where this config comes from
      # @param path [String] the file path
      # @return [Location] a Location object (not yet marked active)
      def build_layer(scope, source, path)
        Location.new(
          agent: :opencode,
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
