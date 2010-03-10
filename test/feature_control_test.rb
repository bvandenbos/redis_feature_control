require File.dirname(__FILE__) + '/test_helper'

class Redis::FeatureControlTest < Test::Unit::TestCase

  def setup
    Redis::FeatureControl.connection_string = 'localhost:9736'
    Redis::FeatureControl.unmock!
    Redis::FeatureControl.features = [:enabled_feature]
    Redis::FeatureControl.redis.flushall
  end

  def test_connection_string_works
    Redis::FeatureControl.connection_string = "redis:1234"
    assert_equal('redis', Redis::FeatureControl.host)
    assert_equal('1234', Redis::FeatureControl.port)
  end

  def test_redis
    assert(Redis::FeatureControl.redis.is_a?(Redis::Namespace))
  end

  def test_unknown_features_raise_errors
    assert_raises(Redis::FeatureControl::UnknownFeatureError) do
      Redis::FeatureControl.enabled?(:some_feature)
    end
  end

  def test_enable_disable
    Redis::FeatureControl.features << :cool_service # add a feature
    assert(Redis::FeatureControl.enabled?(:cool_service)) # should be enabled by default
    assert(!Redis::FeatureControl.disabled?(:cool_service)) # should be enabled by default

    Redis::FeatureControl.enable!(:cool_service)
    assert(Redis::FeatureControl.enabled?(:cool_service)) # should still be enabled

    Redis::FeatureControl.disable!(:cool_service)
    assert(!Redis::FeatureControl.enabled?(:cool_service)) # should still be enabled
    assert(Redis::FeatureControl.disabled?(:cool_service)) # should still be enabled

    Redis::FeatureControl.enable!(:cool_service)
    assert(Redis::FeatureControl.enabled?(:cool_service)) # should still be enabled
  end

  def test_set_status

    Redis::FeatureControl.features << :cool_service # add a feature

    Redis::FeatureControl.set_status(:cool_service, 0.9) # <1
    assert(Redis::FeatureControl.disabled?(:cool_service)) # should still be enabled

    Redis::FeatureControl.set_status(:cool_service, 1.0)
    assert(Redis::FeatureControl.enabled?(:cool_service)) # should still be enabled

    Redis::FeatureControl.set_status(:cool_service, -1)
    assert(Redis::FeatureControl.disabled?(:cool_service)) # should still be enabled

    Redis::FeatureControl.set_status(:cool_service, -1.0)
    assert(Redis::FeatureControl.disabled?(:cool_service)) # should still be enabled

    Redis::FeatureControl.set_status(:cool_service, 42)
    assert(Redis::FeatureControl.enabled?(:cool_service)) # should still be enabled

    Redis::FeatureControl.set_status(:cool_service, -42)
    assert(Redis::FeatureControl.disabled?(:cool_service)) # should still be enabled

  end

  def test_state_string
    Redis::FeatureControl.features << :cool_service # add a feature

    Redis::FeatureControl.enable!(:cool_service)
    assert_equal('enabled', Redis::FeatureControl.state(:cool_service))

    Redis::FeatureControl.disable!(:cool_service)
    assert_equal('disabled', Redis::FeatureControl.state(:cool_service))
  end

  def test_check_feature
    assert_raises(Redis::FeatureControl::UnknownFeatureError) do
      Redis::FeatureControl.enabled?(:some_feature)
    end

    assert_nothing_raised do
      Redis::FeatureControl.enabled?(:enabled_feature)
    end
  end

  def test_mock

    Redis::FeatureControl.mock!
    assert(Redis::FeatureControl.mock?)

    Redis::FeatureControl.unmock!
    assert(!Redis::FeatureControl.mock?)
  end

  def test_mock_enable_disable
    Redis::FeatureControl.mock!

    Redis::FeatureControl.expects(:redis).never # It's mocked, so it shouldn't use redis

    Redis::FeatureControl.features << :cool_service # add a feature
    assert(Redis::FeatureControl.enabled?(:cool_service)) # should be enabled by default
    assert(!Redis::FeatureControl.disabled?(:cool_service)) # should be enabled by default

    Redis::FeatureControl.enable!(:cool_service)
    assert(Redis::FeatureControl.enabled?(:cool_service)) # should still be enabled

    Redis::FeatureControl.disable!(:cool_service)
    assert(!Redis::FeatureControl.enabled?(:cool_service)) # should still be enabled
    assert(Redis::FeatureControl.disabled?(:cool_service)) # should still be enabled

    Redis::FeatureControl.enable!(:cool_service)
    assert(Redis::FeatureControl.enabled?(:cool_service)) # should still be enabled
  end

end