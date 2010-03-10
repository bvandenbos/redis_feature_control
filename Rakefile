$LOAD_PATH.unshift 'lib'

task :default => :test

desc "Run tests"
task :test do
  Dir['test/*_test.rb'].each do |f|
    require f
  end
end

desc "Build a gem"
task :gem => [ :test, :gemspec, :build ]

begin
  begin
    require 'jeweler'
  rescue LoadError
    puts "Jeweler not available. Install it with: "
    puts "gem install jeweler"
  end

  require 'redis/feature_control'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "redis_feature_control"
    gemspec.summary = "Feature enable/disable library on top of Redis"
    gemspec.description = gemspec.summary
    gemspec.email = "bvandenbos@gmail.com"
    gemspec.homepage = "http://github.com/bvandenbos/redis_feature_control"
    gemspec.authors = ["Ben VandenBos"]
    gemspec.version = Redis::FeatureControl::Version
    
    gemspec.add_dependency "redis", ">= 0.1.1"
    gemspec.add_dependency "redis-namespace", ">= 0.2.0"
    gemspec.add_development_dependency "jeweler"
    gemspec.add_development_dependency "mocha"
  end
end


desc "Push a new version to Gemcutter"
task :publish => [ :test, :gemspec, :build ] do
  require 'redis/feature_control'
  system "git tag v#{Redis::FeatureControl::Version}"
  system "git push origin v#{Redis::FeatureControl::Version}"
  system "git push origin master"
  system "gem push pkg/redis_feature_control-#{Redis::FeatureControl::Version}.gem"
  system "git clean -fd"
end
