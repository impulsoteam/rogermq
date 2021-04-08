require 'json'

module Roger
  class QueueNotFound < StandardError; end
  class ExchangeNotFound < StandardError; end

  class App
    @queues ||= {}
    @exchanges ||= {}
    @consumers ||= {}

    class << self
      include Roger::Logging
      attr_accessor :queues, :exchanges, :consumers

      def broker
        @broker ||= Bunny.new(Config.client_uri)
      end

      def channel
        broker.start unless broker.connected?
        @channel ||= broker.create_channel
      end

      def default_exchange
        channel.default_exchange
      end

      def start
        logger.info "RogerMQ started at #{Config.client_uri}" if Config.logging.include?(:start)
        load_consumers!
        bind_consumers!
        queues.each do |_, queue|
          queue.subscribe do |delivery_info, properties, body|
            MessageProcessor.new(delivery_info, properties, body).process
          end
        end
      end

      def stop
        broker.close
        logger.info 'RogerMQ stopped' if Config.logging.include?(:stop)
      end

      private

        def load_consumers!
          glob_path = File.join(Config.consumers_directory, '**', '*_consumer.rb')
          Dir[glob_path].each {  |path| require File.join(Dir.pwd, path) }
        end

        def bind_consumers!
          App.consumers.each do |consumer_key, consumer_value|
            queue_name, exchange_name, bind_options = consumer_value.values_at(:queue_name, :exchange_name, :bind_options)

            exchange = Config.exchange(exchange_name, Config.default_exchange_options)
            queue = Config.queue(queue_name, Config.default_queue_options)
            queue.bind(exchange, bind_options)

            if Config.logging.include?(:bindings)
              log = ["Queue #{queue_name} binded to #{exchange_name}"]
              log << "using routing_key #{bind_options[:routing_key]}" if bind_options[:routing_key].present?
              logger.info log.join(' ')
            end
          end
        end
    end
  end
end
