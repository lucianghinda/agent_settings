# frozen_string_literal: true

module AgentSettings
  # Represents a config file location for an agent.
  #
  # A Location describes where a configuration file is (or would be) stored,
  # whether it exists, and whether it's the currently active configuration.
  # Locations are organized by scope (global vs project) and source
  # (user, system, file, etc.).
  #
  # @example
  #   location = Location.new(
  #     agent: :claude,
  #     scope: :global,
  #     source: 'user',
  #     path: '/Users/me/.claude/settings.json',
  #     exists: true,
  #     active: true,
  #     note: nil
  #   )
  #   location.exists?  #=> true
  #   location.active?  #=> true
  #
  # @attr agent [Symbol] the agent this location belongs to (:claude, :opencode, :codex)
  # @attr scope [Symbol] the scope of this location (:global, :project, :managed, :system, :env)
  # @attr source [String] where this location comes from ('user', 'system', 'file', 'local')
  # @attr path [String] the absolute file path to the config file
  # @attr exists [Boolean] whether the config file exists at this path
  # @attr active [Boolean] whether this is the currently effective config location
  # @attr note [String, nil] optional note about this location
  Location = Data.define(:agent, :scope, :source, :path, :exists, :active, :note) do
    # @return [Boolean] whether the config file exists at this path
    def exists? = exists

    # @return [Boolean] whether this is the currently effective config location
    def active? = active
  end
end
