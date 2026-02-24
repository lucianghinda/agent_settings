# frozen_string_literal: true

require_relative "../test_helper"

class ClaudeAdapterTest < Minitest::Test
  def setup
    @adapter = AgentSettings::Adapters::Claude.new
    @dir = Dir.pwd
  end

  def test_layers_returns_array
    layers = @adapter.layers(dir: @dir, env: {}, trusted: true)
    assert_instance_of Array, layers
    refute layers.empty?
  end

  def test_layers_includes_global
    layers = @adapter.layers(dir: @dir, env: {}, trusted: true)
    global = layers.find { |l| l.scope == :global }
    assert global
    assert global.path.include?(".claude")
  end

  def test_layers_includes_project
    layers = @adapter.layers(dir: @dir, env: {}, trusted: true)
    project = layers.find { |l| l.scope == :project }
    assert project
    assert project.path.include?(".claude")
  end

  def test_env_overrides_empty_without_env
    overrides = @adapter.env_overrides(dir: @dir, env: {}, trusted: true)
    assert_empty overrides
  end

  def test_env_overrides_with_config_dir
    env = { "CLAUDE_CONFIG_DIR" => "/tmp/test_claude" }
    overrides = @adapter.env_overrides(dir: @dir, env: env, trusted: true)
    assert_equal 1, overrides.length
    assert_equal "CLAUDE_CONFIG_DIR", overrides.first.name
    assert overrides.first.path.include?("settings.json")
  end

  def test_warnings_empty
    warnings = @adapter.warnings(dir: @dir, env: {}, trusted: true)
    assert_empty warnings
  end
end
