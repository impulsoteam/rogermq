require 'logger'
require 'time'

module Roger
  class RogerLogFormatter < Logger::Formatter
    def call(severity, time, program_name, message)
      "#{time.utc.iso8601} #{Process.pid} #{severity} -- #{message}\n"
    end
  end

  module Logging
    def self.setup_logger
      @logger = Logger.new($stdout).tap do |l|
        l.level = Config.log_level
        l.formatter = RogerLogFormatter.new
      end
    end

    def self.logger
      @logger || setup_logger
    end

    def self.logger=(logger)
      @logger = logger
    end

    def logger
      Roger::Logging.logger
    end
  end
end
