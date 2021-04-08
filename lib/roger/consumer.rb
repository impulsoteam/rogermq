module Roger
  module Consumer
    extend ActiveSupport::Concern

    included do
      include Roger::Logging
      attr_reader :body, :properties, :delivery_info

      def initialize(delivery_info, properties, body = nil)
        @delivery_info = delivery_info
        @properties = properties
        @body = body
      end
    end

    class_methods do
      include Roger::Logging

      def call(method, info, properties, body)
        return new(info, properties).send(method, *body) if info[:exchange] == Config.rpc_channel
        new(info, properties, body).send(method)
      end

      def rpc(routing_key, method = :process)
        bind(Config.rpc_channel, Config.rpc_channel, routing_key: routing_key, method: method)
      end

      def bind(exchange_name, queue_name, bind_options = {})
        consumer_key = [exchange_name, queue_name, bind_options[:routing_key]].compact.join('.')
        method = bind_options.delete(:method) || :process

        App.consumers[consumer_key] ||= {
          klass: ancestors.first,
          queue_name: queue_name,
          exchange_name: exchange_name,
          bind_options: bind_options,
          method: method
        }
      end
    end
  end
end
