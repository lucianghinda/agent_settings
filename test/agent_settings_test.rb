# frozen_string_literal: true

require_relative "test_helper"

class AgentSettingsTest < Minitest::Test
  def test_version_defined
    assert AgentSettings::VERSION
  end

  def test_global_returns_location_for_claude
    location = AgentSettings.global(:claude)
    assert_equal :claude, location.agent
    assert_equal :global, location.scope
  end

  def test_global_returns_location_for_opencode
    location = AgentSettings.global(:opencode)
    assert_equal :opencode, location.agent
    assert_equal :global, location.scope
  end

  def test_global_returns_location_for_codex
    location = AgentSettings.global(:codex)
    assert_equal :codex, location.agent
    assert_equal :global, location.scope
  end

  def test_global_raises_for_unknown_agent
    assert_raises(AgentSettings::UnknownAgentError) do
      AgentSettings.global(:unknown)
    end
  end

  def test_project_returns_location_for_claude
    location = AgentSettings.project(:claude, dir: Dir.pwd)
    assert_equal :claude, location.agent
    assert_equal :project, location.scope
  end

  def test_project_returns_location_for_opencode
    location = AgentSettings.project(:opencode, dir: Dir.pwd)
    assert_equal :opencode, location.agent
    assert_equal :project, location.scope
  end

  def test_project_returns_location_for_codex
    location = AgentSettings.project(:codex, dir: Dir.pwd)
    assert_equal :codex, location.agent
    assert_equal :project, location.scope
  end

  def test_resolve_returns_agent_config_path
    result = AgentSettings.resolve(:claude, dir: Dir.pwd)
    assert_instance_of AgentSettings::AgentConfigPath, result
    assert_equal :claude, result.agent
  end

  def test_all_returns_hash_with_all_agents
    results = AgentSettings.all(dir: Dir.pwd)
    assert_instance_of Hash, results
    assert_includes results.keys, :claude
    assert_includes results.keys, :opencode
    assert_includes results.keys, :codex
  end

  def test_location_predicate_methods
    location = AgentSettings::Location.new(
      agent: :claude,
      scope: :global,
      source: "user",
      path: "/path/to/config",
      exists: true,
      active: true,
      note: nil
    )
    assert location.exists?
    assert location.active?
  end

  def test_env_override_predicate_methods
    override = AgentSettings::EnvOverride.new(
      agent: :claude,
      name: "TEST_VAR",
      value: "/test/path",
      path: "/test/path",
      exists: true,
      active: true,
      note: nil
    )
    assert override.exists?
    assert override.active?
  end

  def test_agent_config_path_custom_config
    config_path = AgentSettings::AgentConfigPath.new(
      agent: :claude,
      effective: nil,
      global: nil,
      project: nil,
      layers: [],
      env_overrides: [],
      warnings: []
    )
    refute config_path.custom_config?

    config_path_with_override = AgentSettings::AgentConfigPath.new(
      agent: :claude,
      effective: nil,
      global: nil,
      project: nil,
      layers: [],
      env_overrides: [AgentSettings::EnvOverride.new(
        agent: :claude,
        name: "TEST",
        value: "x",
        path: "x",
        exists: true,
        active: true,
        note: nil
      )],
      warnings: []
    )
    assert config_path_with_override.custom_config?
  end
end
