
require 'optparse'
require 'logger'
require 'dotenv/load'

module Roger
  class Config
    @log_level ||= Logger::INFO
    @client_uri ||= 'amqp://guest:guest@localhost:5672/'
    @rpc_route_name ||= 'remote_procedure_calls'
    @consumers_directory ||= 'consumers/**/*.rb'

    class << self
      attr_accessor :client_uri, :rpc_route_name, :log_level, :consumers_directory

      def parse!
        parser = OptionParser.new do |opts|
          opts.on('-C', '--config PATH', 'Load config file') do |v|
            require_relative File.join(Dir.pwd, v)
          end

          opts.on('-r', '--load-rails', 'Load rails (only when rails is present)') do |v|
            load_rails!
          end
        end

        parser.parse!
      end

      def load_rails!
        rails_path = File.expand_path(File.join('.', 'config', 'environment.rb'))
        raise Interrupt unless File.exist?(rails_path)
        ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || 'development'
        require rails_path
        ::Rails.application.eager_load!
      end
    end
  end
end
