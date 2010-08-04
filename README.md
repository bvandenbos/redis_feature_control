redis_feature_control
=====================

Redis_feature_control is a module to mark features/services as enabled or disabled
so jobs can take appropriate action.


### Why?

Sometimes you depend on services.  Sometimes these services go down.  Sometimes
you want to explicitly turn off services and have your app know the service is
turned off.  That way your app can display a pretty message to a user
rather than trying a service and waiting for it to time out.  Maybe your backend
job depends on a service.  When it notices it's disabled, it can sleep or delay
that job to sometime in the future without having to test the service.



### Usage

Install it:

    gem install redis_feature_control

Configure it:

    require 'rubygems'
    require 'redis/feature_control'
    Redis::FeatureControl.connection_string = "redis_server:6379"

Then add your features/services to it:

    Redis::FeatureControl.features << :data_warehouse
    Redis::FeatureControl.features << :cc_gateway
    Redis::FeatureControl.features << :hulu

Then see if they are enabled and toggle them:

    # on by default
    Redis::FeatureControl.enabled?(:cc_gateway) # => true

    # disabling...
    Redis::FeatureControl.disable!(:cc_gateway)
    Redis::FeatureControl.enabled?(:cc_gateway) # => false
    Redis::FeatureControl.state(:cc_gateway) # => "disabled"

    # enabling...
    Redis::FeatureControl.enable!(:cc_gateway)
    Redis::FeatureControl.enabled?(:cc_gateway) # => true
    Redis::FeatureControl.disabled?(:cc_gateway) # => false
    Redis::FeatureControl.state(:cc_gateway) # => "enabled"

### Mocking for Test/Development

Since you don't always have redis available in development and test, sometimes
it's nice to just keep the state of features in memory.  You can enable the mock
behavior like so:

    Redis::FeatureControl.mock!

It will work exactly the same as when it's using redis, but it will only store
the states of features in memory.

To stop mocking:

    Redis::FeatureControl.unmock!

