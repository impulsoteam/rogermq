module Roger
  module Consumer
    attr_reader :body, :properties, :delivery_info

    def logger
      @logger ||= Rails.logger
    end

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
        Roger.routes << Route.new(ancestors.first, exchange, queue_name, routing_key)
      end
    end
  end
end
