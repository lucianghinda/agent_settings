# frozen_string_literal: true

module AgentSettings
  module Adapters
    # Adapter for Codex agent configuration.
    #
    # Codex stores configuration in TOML files:
    #
    # - Global: ~/.codex/config.toml (user-level config)
    # - Project: .codex/config.toml (project-level config, trusted only)
    # - System: /etc/codex/config.toml (system-level config)
    #
    # Codex has a unique "trust" model - project config is only used
    # for trusted projects. Untrusted projects will have a warning
    # and no project layer.
    #
    # Environment variable CODEX_HOME can override the home directory
    # where the global config is located.
    #
    # @example Trusted project
    #   adapter = Codex.new
    #   layers = adapter.layers(dir: "/work/my_app", env: ENV, trusted: true)
    #   layers.count  #=> includes project layer
    #
    # @example Untrusted project
    #   layers = adapter.layers(dir: "/untrusted", env: ENV, trusted: false)
    #   adapter.warnings(...)  #=> ["Project config ignored for untrusted project"]
    class Codex
      # Get all config layers for Codex.
      #
      # Returns an array of Location objects for global, system (if exists),
      # and project (if trusted) configs. Project config is excluded for
      # untrusted projects.
      #
      # @param dir [String] project directory path
      # @param env [Hash] environment variables hash (CODEX_HOME is used)
      # @param trusted [Boolean] whether the project is trusted
      # @return [Array<Location>] config layers in precedence order
      def layers(dir:, env:, trusted:)
        build_layers(dir, env, trusted)
      end

      # Get environment variable overrides for Codex.
      #
      # Checks for CODEX_HOME environment variable. When set, it changes
      # the base directory for the global config (from ~ to the specified path).
      #
      # @param dir [String] project directory path (unused)
      # @param env [Hash] environment variables hash
      # @param trusted [Boolean] whether the project is trusted (unused)
      # @return [Array<EnvOverride>] detected environment overrides
      def env_overrides(dir:, env:, trusted:) # rubocop:disable Lint/UnusedMethodArgument
        build_env_overrides(env)
      end

      # Get warnings for Codex configuration.
      #
      # Returns a warning if the project is untrusted but has a config file.
      # This helps users understand why their project config is being ignored.
      #
      # @param dir [String] project directory path
      # @param env [Hash] environment variables hash (unused)
      # @param trusted [Boolean] whether the project is trusted
      # @return [Array<String>] warning messages
      def warnings(dir:, env:, trusted:) # rubocop:disable Lint/UnusedMethodArgument
        warnings = []
        if !trusted && File.exist?(File.join(dir, ".codex", "config.toml"))
          warnings << "Project config ignored for untrusted project"
        end
        warnings
      end

      private

      # Build the list of config layers.
      #
      # Creates Location objects for global, system (if exists), and
      # project (if trusted) configs. CODEX_HOME can override the
      # home directory for global config location.
      #
      # @param dir [String] project directory path
      # @param env [Hash] environment variables hash
      # @param trusted [Boolean] whether the project is trusted
      # @return [Array<Location>] config layers with active flag set
      def build_layers(dir, env, trusted)
        home = env["CODEX_HOME"] || Dir.home
        global_path = File.join(home, ".codex", "config.toml")
        system_path = "/etc/codex/config.toml"
        project_path = File.join(dir, ".codex", "config.toml")

        layers = []
        layers << build_layer(:global, "user", global_path)
        layers << build_layer(:system, "system", system_path) if File.exist?(system_path)

        layers << build_layer(:project, "file", project_path) if trusted

        mark_active(layers)
      end

      # Build environment variable overrides.
      #
      # Checks if CODEX_HOME is set and creates an EnvOverride for it.
      # The override's path is the config.toml file within the specified
      # home directory's .codex subdirectory.
      #
      # @param env [Hash] environment variables hash
      # @return [Array<EnvOverride>] detected overrides
      def build_env_overrides(env) # rubocop:disable Metrics/MethodLength -- constructs EnvOverride with all required attributes
        overrides = []

        if (value = env["CODEX_HOME"])
          path = File.join(value, ".codex", "config.toml")
          overrides << EnvOverride.new(
            agent: :codex,
            name: "CODEX_HOME",
            value: value,
            path: path,
            exists: File.exist?(path),
            active: File.exist?(path),
            note: "Home directory override"
          )
        end

        overrides
      end

      # Build a Location object for a config layer.
      #
      # @param scope [Symbol] the scope (:global, :project, :system)
      # @param source [String] where this config comes from
      # @param path [String] the file path
      # @return [Location] a Location object (not yet marked active)
      def build_layer(scope, source, path)
        Location.new(
          agent: :codex,
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
