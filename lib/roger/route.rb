module Roger
  class Route
    attr_accessor :consumer, :exchange, :queue, :routing_key, :consumer_key

    def initialize(consumer, exchange, queue, routing_key = nil)
      @consumer = consumer
      @exchange = exchange
      @queue = queue
      @routing_key = routing_key
    end
  end
end
