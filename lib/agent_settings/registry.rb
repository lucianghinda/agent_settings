# frozen_string_literal: true

module AgentSettings
  # Registry mapping agent symbols to their adapter classes.
  #
  # The Registry is responsible for knowing which adapters exist and
  # providing the correct adapter instance for a given agent symbol.
  # It also defines the list of supported agents.
  #
  # @api private
  module Registry
    # List of supported agent symbols.
    AGENTS = %i[claude opencode codex].freeze

    module_function

    # Get the adapter instance for an agent.
    #
    # Returns a new instance of the appropriate adapter class for the
    # given agent symbol. Uses pattern matching to select the adapter.
    #
    # @param agent [Symbol] the agent identifier (:claude, :opencode, :codex)
    # @return [Object] an instance of the appropriate adapter class
    # @raise [UnknownAgentError] if the agent symbol is not recognized
    #
    # @example
    #   adapter = Registry.adapter(:claude)  #=> AgentSettings::Adapters::Claude instance
    #   adapter.layers(dir: Dir.pwd, env: {}, trusted: true)
    def adapter(agent)
      case agent
      in :claude then Adapters::Claude.new
      in :opencode then Adapters::Opencode.new
      in :codex then Adapters::Codex.new
      else
        raise UnknownAgentError, "Unknown agent: #{agent}. Supported: #{AGENTS.join(", ")}"
      end
    end
  end
end
