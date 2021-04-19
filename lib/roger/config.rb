
require 'optparse'
require 'logger'
require 'dotenv/load'

module Roger
  class Config
    @log_level ||= Logger::INFO
    @client_uri ||= nil
    @consumers_directory ||= 'consumers'
    @default_queue_options ||= { durable: true }
    @default_exchange_options ||= { type: 'fanout' }
    @app_id ||= 'roger'
    @rpc_channel ||= 'remote_procedure_calls'
    @rpc_timeout ||= 180
    @logging ||= %i[start bindings receives replies]

    class << self
      include Roger::Logging
      attr_accessor :client_uri, :rpc_route_name, :log_level, :consumers_directory, :default_exchange_options,
        :default_queue_options, :app_id, :rpc_channel, :rpc_timeout, :logging

      def parse!
        OptionParser.new do |opts|
          opts.on('-C', '--config PATH', 'Load config file') { |v| require File.join(Dir.pwd, v) }
          opts.on('--rails', 'Load rails (only when rails is present)') { |v| load_rails! }
        end.parse!
      end

      def load_rails!
        rails_path = File.expand_path(File.join(Dir.pwd, 'config', 'environment.rb'))

        unless File.exists?(rails_path)
          logger.error "Rails not found"
          exit(1)
        end

        ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || 'development'
        require rails_path
        ::Rails.application.eager_load!
      end

      def exchange(exchange_name, options = {})
        App.exchanges[exchange_name] ||= App.channel.exchange(exchange_name, options)
      end

      def queue(queue_name, options = {})
        App.queues[queue_name] ||= App.channel.queue(queue_name, options)
      end
    end
  end
end
