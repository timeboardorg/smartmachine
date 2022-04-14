require "logger"

$stdout.sync = true

module SmartMachine
  module Logger
    def logger
      @logger ||= SmartMachine::Logger.logger_for(self.class.name)
    end

    # Use a hash class-ivar to cache a unique Logger per class:
    @loggers = {}

    def self.included(base)
      class << base
        def logger
          @logger ||= SmartMachine::Logger.logger_for(self.name)
        end
      end
    end

    class << self
      def logger_for(classname)
        @loggers[classname] ||= configure_logger_for(classname)
      end

      def configure_logger_for(classname)
        logger = ::Logger.new($stdout)
        logger.level = ::Logger.const_get("#{SmartMachine.config.logger_level}".upcase)
        logger.progname = classname
        logger
      end
    end
  end
end
