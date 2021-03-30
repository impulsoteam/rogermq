module Roger
  class RpcRoute
    attr_accessor :consumer, :routing_key

    def initialize(consumer, routing_key)
      @consumer = consumer
      @routing_key = routing_key
    end
  end
end
