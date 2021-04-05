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
      Roger.broker.start unless Roger.broker.connected?
      initialize_subscription
      exchange.publish(arguments.to_json, publish_options)
      lock.synchronize { condition.wait(lock, timeout) }
      finish_subscription

      @response
    end

    private

    def initialize_subscription
      queue.bind(exchange, routing_key: queue.name)
      queue.subscribe do |delivery_info, properties, payload|
        if properties[:correlation_id] == message_id
          @response = JSON.parse(payload) rescue payload.to_s
          lock.synchronize { condition.signal }
        end
      end
    end

    def finish_subscription
      queue.delete
    end

    def publish_options
      {
        routing_key: routing_key,
        reply_to: queue.name,
        message_id: message_id
      }
    end

    def channel
      @channel ||= Roger.channel
    end

    def queue
      @queue ||= channel.queue('', exclusive: true)
    end

    def exchange
      @exchange ||= channel.exchange(Config.rpc_route_name, type: :direct, auto_delete: true)
    end

    def message_id
      @message_id ||= SecureRandom.uuid
    end
  end
end
