# -*- encoding: utf-8 -*-
require File.expand_path("../lib/redis/feature_control/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "redis_feature_control"
  s.version     = Redis::FeatureControl::Version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Ben VandenBos']
  s.email       = ['bvandenbos@gmail.com']
  s.homepage    = "http://github.com/bvandenbos/redis_feature_control"
  s.summary     = "Feature enable/disable library on top of Redis"
  s.description = "Feature enable/disable library on top of Redis"
  
  s.required_rubygems_version = ">= 1.3.6"
  s.add_development_dependency "bundler", ">= 1.0.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
  
  s.add_runtime_dependency("redis", [">= 0.1.1"])
  s.add_runtime_dependency("redis-namespace", [">= 0.2.0"])
  s.add_development_dependency("mocha", [">= 0"])
  s.add_development_dependency("rake")
  s.add_development_dependency("test-unit")
  
end

