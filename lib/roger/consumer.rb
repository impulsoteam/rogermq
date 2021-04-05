module Roger
  module Consumer
    include Roger::Logging

    attr_reader :body, :properties, :delivery_info

    def initialize(payload)
      @body = payload.body
      @properties = payload.properties
      @delivery_info = payload.delivery_info
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def route(exchange, queue_name, routing_key = nil)
        consumer_key = [exchange, queue_name, routing_key].reject { |c| c.to_s.strip.empty? }.join('.')
        Roger.routes[consumer_key] ||= Route.new(ancestors.first, exchange, queue_name, routing_key)
      end

      def rpc(routing_key)
        Roger.rpc_routes[routing_key] ||= RpcRoute.new(ancestors.first, routing_key)
      end
    end
  end
end
