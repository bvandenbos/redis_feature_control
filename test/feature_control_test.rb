require File.dirname(__FILE__) + '/test_helper'

class Redis::FeatureControlTest < Test::Unit::TestCase

  def setup
    control.connection_string = 'localhost:9736'
    control.unmock!
    control.features = [:enabled_feature]
    control.redis.flushall
  end

  def test_connection_string_works
    control.connection_string = "redis:1234"
    assert_equal('redis', control.host)
    assert_equal('1234', control.port)
  end

  def test_connection_works
    redis = Redis.new(:host => 'localhost', :port => 9736, :thread_safe => true)
    redis_namespace = Redis::Namespace.new(:feature_control_test, :redis => redis)
    control.connection = redis_namespace
    control.features = [:some_feature]
    control.enable!(:some_feature)
    assert redis.exists('feature_control_test:some_feature')
  end

  def test_redis
    assert(control.redis.is_a?(Redis::Namespace))
  end

  def test_unknown_features_raise_errors
    assert_raises(control::UnknownFeatureError) do
      control.enabled?(:some_feature)
    end
  end

  def test_enable_disable
    control.features << :cool_service # add a feature
    assert(control.enabled?(:cool_service)) # should be enabled by default
    assert(!control.disabled?(:cool_service)) # should be enabled by default

    control.enable!(:cool_service)
    assert(control.enabled?(:cool_service)) # should still be enabled

    control.disable!(:cool_service)
    assert(!control.enabled?(:cool_service)) # should still be enabled
    assert(control.disabled?(:cool_service)) # should still be enabled

    control.enable!(:cool_service)
    assert(control.enabled?(:cool_service)) # should still be enabled
  end

  def test_set_status
    control.features << :cool_service # add a feature

    control.set_status(:cool_service, 0.9) # <1
    assert(control.disabled?(:cool_service)) # should still be enabled

    control.set_status(:cool_service, 1.0)
    assert(control.enabled?(:cool_service)) # should still be enabled

    control.set_status(:cool_service, -1)
    assert(control.disabled?(:cool_service)) # should still be enabled

    control.set_status(:cool_service, -1.0)
    assert(control.disabled?(:cool_service)) # should still be enabled

    control.set_status(:cool_service, 42)
    assert(control.enabled?(:cool_service)) # should still be enabled

    control.set_status(:cool_service, -42)
    assert(control.disabled?(:cool_service)) # should still be enabled
  end

  def test_state_string
    control.features << :cool_service # add a feature

    control.enable!(:cool_service)
    assert_equal('enabled', control.state(:cool_service))

    control.disable!(:cool_service)
    assert_equal('disabled', control.state(:cool_service))
  end

  def test_check_feature
    assert_raises(control::UnknownFeatureError) do
      control.enabled?(:some_feature)
    end

    assert_nothing_raised do
      control.enabled?(:enabled_feature)
    end
  end

  def test_mock

    control.mock!
    assert(control.mock?)

    control.unmock!
    assert(!control.mock?)
  end

  def test_mock_enable_disable
    control.mock!

    control.expects(:redis).never # It's mocked, so it shouldn't use redis

    control.features << :cool_service # add a feature
    assert(control.enabled?(:cool_service)) # should be enabled by default
    assert(!control.disabled?(:cool_service)) # should be enabled by default

    control.enable!(:cool_service)
    assert(control.enabled?(:cool_service)) # should still be enabled

    control.disable!(:cool_service)
    assert(!control.enabled?(:cool_service)) # should still be enabled
    assert(control.disabled?(:cool_service)) # should still be enabled

    control.enable!(:cool_service)
    assert(control.enabled?(:cool_service)) # should still be enabled
  end
  
  private
  
  def control
    Redis::FeatureControl
  end

end