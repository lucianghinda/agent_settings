# frozen_string_literal: true

require_relative "../test_helper"

class OpencodeAdapterTest < Minitest::Test
  def setup
    @adapter = AgentSettings::Adapters::Opencode.new
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
    assert global.path.include?(".config/opencode")
  end

  def test_env_overrides_empty_without_env
    overrides = @adapter.env_overrides(dir: @dir, env: {}, trusted: true)
    assert_empty overrides
  end

  def test_env_overrides_with_config
    env = { "OPENCODE_CONFIG" => "/tmp/test_opencode.json" }
    overrides = @adapter.env_overrides(dir: @dir, env: env, trusted: true)
    assert_equal 1, overrides.length
    assert_equal "OPENCODE_CONFIG", overrides.first.name
  end

  def test_env_overrides_with_config_dir
    env = { "OPENCODE_CONFIG_DIR" => "/tmp/test_opencode_dir" }
    overrides = @adapter.env_overrides(dir: @dir, env: env, trusted: true)
    assert_equal 1, overrides.length
    assert_equal "OPENCODE_CONFIG_DIR", overrides.first.name
  end

  def test_env_overrides_with_config_content
    env = { "OPENCODE_CONFIG_CONTENT" => '{"test": true}' }
    overrides = @adapter.env_overrides(dir: @dir, env: env, trusted: true)
    assert_equal 1, overrides.length
    assert_equal "OPENCODE_CONFIG_CONTENT", overrides.first.name
    assert overrides.first.active?
  end

  def test_warnings_empty
    warnings = @adapter.warnings(dir: @dir, env: {}, trusted: true)
    assert_empty warnings
  end
end
