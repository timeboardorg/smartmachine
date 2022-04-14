require "active_support/core_ext/hash/keys"
require "erb"

module SmartMachine
  class Configuration < SmartMachine::Base

    def initialize
    end

    def config
      @config ||= OpenStruct.new(grids: grids)
    end

    private

    def grids
      @grids ||= OpenStruct.new(elasticsearch: elasticsearch, minio: minio, mysql: mysql, prereceiver: prereceiver, redis: redis)
    end

    def elasticsearch
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/elasticsearch.yml always exists
      if File.exist? "config/elasticsearch.yml"
        deserialize(IO.binread("config/elasticsearch.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/elasticsearch.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/elasticsearch.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def minio
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/minio.yml always exists
      if File.exist? "config/minio.yml"
        deserialize(IO.binread("config/minio.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/minio.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/minio.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def mysql
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/mysql.yml always exists
      if File.exist? "config/mysql.yml"
        deserialize(IO.binread("config/mysql.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/mysql.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/mysql.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def prereceiver
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/prereceiver.yml always exists
      if File.exist? "config/prereceiver.yml"
        deserialize(IO.binread("config/prereceiver.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/prereceiver.yml" # To ensure file exists when inside the pre-receive hook of prereceiver.
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/prereceiver.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def redis
      # Once the SmartMachine.config assignments in smart_machine.rb file has been removed, then this file exist condition can be removed to ensure that config/redis.yml always exists
      if File.exist? "config/redis.yml"
        deserialize(IO.binread("config/redis.yml")).deep_symbolize_keys
      elsif File.exist? "#{File.expand_path('~')}/machine/config/redis.yml"
        deserialize(IO.binread("#{File.expand_path('~')}/machine/config/redis.yml")).deep_symbolize_keys
      else
        {}
      end
    end

    def deserialize(config)
      YAML.load(ERB.new(config).result).presence || {}
    end
  end
end
