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

      def client_uri
        @client_uri ||= ENV['CLOUDAMQP_URL']
      end

      def rpc_route_name
        @rpc_route_name ||= 'roger.remote_procedure_calls'
      end
    end
  end
end
