require "ostruct"
require "yaml"

require 'smart_machine/version'
require 'smart_machine/base'

require 'smart_machine/configuration'
require 'smart_machine/credentials'

require 'smart_machine/scp'
require 'smart_machine/ssh'
require 'smart_machine/machine'

require 'smart_machine/docker'
require 'smart_machine/engine'
require 'smart_machine/syncer'

require 'smart_machine/apps/app'
require 'smart_machine/apps/container'
require 'smart_machine/apps/manager'

require 'smart_machine/buildpackers/buildpacker'
require 'smart_machine/buildpackers/rails'

require 'smart_machine/grids/elasticsearch'
require 'smart_machine/grids/minio'
require 'smart_machine/grids/mysql'
require 'smart_machine/grids/nginx'
require 'smart_machine/grids/prereceiver'
require 'smart_machine/grids/redis'
# require 'smart_machine/grids/scheduler'
# require 'smart_machine/grids/solr'

module SmartMachine
  class Error < StandardError; end

  def self.credentials
    @@credentials ||= OpenStruct.new(SmartMachine::Credentials.new.config)
  end

  def self.config
    @@config ||= OpenStruct.new(SmartMachine::Configuration.new.config)
  end
end

SmartMachine.config.gem_dir = Gem::Specification.find_by_name("smartmachine").gem_dir
# This will only work inside the smartmachine engine.
if File.exist?("#{File.expand_path('~')}/machine/config/environment.rb")
  require "#{File.expand_path('~')}/machine/config/environment"
end
