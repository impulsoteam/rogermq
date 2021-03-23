require 'logger'

module Roger
  class Config
    class << self
      def log_level
        @log_level ||= Logger::INFO
      end

      def log_level=(log_level)
        @log_level = log_level
      end
    end
  end
end
