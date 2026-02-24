# frozen_string_literal: true

require_relative "../test_helper"

class CodexAdapterTest < Minitest::Test
  def setup
    @adapter = AgentSettings::Adapters::Codex.new
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
    assert global.path.include?(".codex")
  end

  def test_layers_includes_project_when_trusted
    layers = @adapter.layers(dir: @dir, env: {}, trusted: true)
    project = layers.find { |l| l.scope == :project }
    assert project
  end

  def test_layers_excludes_project_when_untrusted
    layers = @adapter.layers(dir: @dir, env: {}, trusted: false)
    project = layers.find { |l| l.scope == :project }
    assert_nil project
  end

  def test_env_overrides_empty_without_env
    overrides = @adapter.env_overrides(dir: @dir, env: {}, trusted: true)
    assert_empty overrides
  end

  def test_env_overrides_with_codex_home
    env = { "CODEX_HOME" => "/tmp/test_codex_home" }
    overrides = @adapter.env_overrides(dir: @dir, env: env, trusted: true)
    assert_equal 1, overrides.length
    assert_equal "CODEX_HOME", overrides.first.name
  end

  def test_warnings_empty_when_trusted
    warnings = @adapter.warnings(dir: @dir, env: {}, trusted: true)
    assert_empty warnings
  end
end
