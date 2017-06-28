require 'rubygems'
require 'redis'
require 'redis/namespace'
require 'forwardable'

#
# Redis::FeatureControl
#
# The point of this is to have a very simple way to turn pieces of the site on
# and off without having to load your entire Rails stack (models, etc).
#
# How it stores stuff in Redis:
# Features default on, so if the value in redis is nil, it's considered
# enabled.  The value is "1" when explicitly turned on and "0" when off.
#
class Redis

  class FeatureControl
    extend Forwardable

    class Redis::FeatureControl::UnknownFeatureError < RuntimeError; end;

    def_delegators self, :check_feature!, :mock?, :mock_feature_hash, :redis, :get_value

    def initialize(dynamic_value)
      @dynamic_value = dynamic_value
    end

    def enabled?(feature)
      feature_control_value = get_value(feature)
      feature_control_value >= user_value unless feature_control_value == 0.0
    rescue Errno::ECONNREFUSED
      true # default to enabled if we can't connect to redis
    end

    def user_value
      if defined? @dynamic_value
        Digest::SHA1.hexdigest(@dynamic_value.to_s).to_i(16) % 1_000_000 / 1_000_000.0
      else
        1
      end
    end

    class << self

      attr_accessor :features

      def features
        @features ||= []
      end

      def host
        @host ||= 'localhost'
      end

      def port
        @port ||= 6379
      end

      # Redis::FeatureControl
      def connection_string=(value)
        @host, @port = value.split(":", 2)
        redis_connect!
      end
      
      # Set the redis instance directly.
      def connection=(redis)
        @redis = redis
      end

      # Connects to redis on the current host/port and sets the redis object
      def redis_connect!
        redis = Redis.new(:host => host, :port => port, :thread_safe => true)
        @redis = Redis::Namespace.new(:feature_control, :redis => redis)
      end

      def redis
        if @redis.nil?
          begin
            redis_connect!
          rescue Errno::ECONNREFUSED
          end
        end
        @redis
      end

      def get_value(feature)
        check_feature!(feature)
        feature_value = mock? ? mock_feature_hash[feature.to_s] : redis.get(feature.to_s)
        (feature_value || 1).to_f
      end

      def set_value!(feature, value)
        value = value.to_f
        check_feature!(feature)

        value = 0 if value < 0
        value = 1 if value > 1

        if mock?
          mock_feature_hash[feature.to_s] = value
        else
          redis.set(feature.to_s, value)
        end
      rescue Errno::ECONNREFUSED
        # Ignore
      end

      def disabled?(feature)
        !enabled?(feature)
      end

      def enabled?(feature)
        get_value(feature.to_s) == 1
      rescue Errno::ECONNREFUSED
        true # default to enabled if we can't connect to redis
      end

      def enable!(feature)
        set_value!(feature, 1)
      end

      def disable!(feature)
        set_value!(feature.to_s, 0)
      rescue Errno::ECONNREFUSED
        # Ignore
      end

      # Backwards compatibility
      # value >=1 enable the feature
      # value <1 disable the feature
      def set_status(feature, value)
        value = value.to_i
        if value >= 1
          enable!(feature)
        else
          disable!(feature)
        end
      end

      # Returns a string for the state of the feature
      def state(feature)
        enabled?(feature) ? 'enabled' : 'disabled'
      end

      def check_feature!(feature)
        raise Redis::FeatureControl::UnknownFeatureError unless features.include?(feature.to_sym)
      end

      # This redfines enabled/disabled to only use class variables instead of connecting
      # to redis.  This allows you to run tests w/out a connection to redis
      def mock!
        @mock = true
      end

      def unmock!
        @mock = false
      end

      def mock?
        @mock
      end

      def mock_feature_hash
        @feature_hash ||= {}
      end

    end
    
  end

end
