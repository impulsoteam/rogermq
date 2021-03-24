module Roger
  class Route
    attr_accessor :consumer, :exchange, :queue, :routing_key, :route_params

    def initialize(consumer, exchange, queue, routing_key = nil, route_params = { durable: true, auto_delete: false })
      @consumer = consumer
      @exchange = exchange
      @queue = queue
      @routing_key = routing_key
      @route_params = route_params
    end
  end
end
