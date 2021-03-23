module Roger
  module Consumer
    include Roger::Logging
    attr_reader :delivery_info, :properties, :body

    def initialize(delivery_info, properties, body)
      @delivery_info = delivery_info
      @properties = properties
      @body = JSON.parse(body) rescue body.to_s
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
