module Roger
  class Rpc
    attr_reader :routing_key, :lock, :condition, :timeout

    def initialize(routing_key, timeout = 30)
      @routing_key = routing_key
      @timeout = timeout
    end

    def call(*arguments)
      @lock = Mutex.new
      @condition = ConditionVariable.new
      initialize_subscription
      exchange.publish(arguments.to_json, publish_options)
      lock.synchronize { condition.wait(lock, timeout) }
      finish_subscription

      @response
    end

    private

    def initialize_subscription
      bunny_client.start
      queue.bind(exchange, routing_key: queue.name)
      queue.subscribe do |delivery_info, properties, payload|
        @response = JSON.parse(payload) rescue payload.to_s
        lock.synchronize { condition.signal }
      end
    end

    def finish_subscription
      queue.delete
      channel.close
      bunny_client.close
    end

    def publish_options
      {
        routing_key: routing_key,
        reply_to: queue.name,
        message_id: call_id
      }
    end

    def bunny_client
      @bunny_client ||= Bunny.new(Config.client_uri)
    end

    def channel
      @channel ||= bunny_client.create_channel
    end

    def queue
      @queue ||= channel.queue('', exclusive: true)
    end

    def exchange
      @exchange ||= channel.exchange(Config.rpc_route_name, type: :direct, auto_delete: true)
    end

    def call_id
      @call_id ||= SecureRandom.uuid
    end
  end
end
