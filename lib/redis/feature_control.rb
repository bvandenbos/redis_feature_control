require 'rubygems'
require 'redis'
require 'redis/namespace'

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

  module FeatureControl

    class Redis::FeatureControl::UnknownFeatureError < RuntimeError; end;

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

      def disabled?(feature)
        check_feature!(feature)
        !enabled?(feature)
      end

      def enabled?(feature)
        check_feature!(feature)
        if mock?
          mock_feature_hash[feature.to_s].nil? || true == mock_feature_hash[feature.to_s]
        else
          (redis.get(feature.to_s) || 1).to_i == 1
        end
      rescue Errno::ECONNREFUSED
        true # default to enabled if we can't connect to redis
      end

      def enable!(feature)
        check_feature!(feature)
        if mock?
          mock_feature_hash[feature.to_s] = true
        else
          redis.set(feature.to_s, 1)
        end
      rescue Errno::ECONNREFUSED
        # Ignore
      end

      def disable!(feature)
        check_feature!(feature)
        if mock?
          mock_feature_hash[feature.to_s] = false
        else
          redis.set(feature.to_s, 0)
        end
      rescue Errno::ECONNREFUSED
        # Ignore
      end

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