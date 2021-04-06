module Roger
  class Rpc
    include Roger::Logging

    class TimeoutError < StandardError; end
    class ResponseError < StandardError; end

    attr_reader :routing_key, :lock, :condition, :timeout

    def initialize(routing_key, timeout = 30)
      @routing_key = routing_key
      @timeout = timeout
      @response = TimeoutError.new('No response from rpc call')
    end

    def call(*arguments)
      @lock = Mutex.new
      @condition = ConditionVariable.new
      initialize_subscription
      exchange.publish(arguments.to_json, publish_options)
      lock.synchronize { condition.wait(lock, timeout) }
      finish_subscription

      raise @response if @response.is_a?(TimeoutError)
      raise ResponseError.new(@response['result']) unless @response['success']
      @response['result']
    rescue Interrupt
      finish_subscription
      logger.info '[ i ] Rpc call cancelled'
    end

    private

    def initialize_subscription
      Roger.broker.start unless Roger.broker.connected?
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

    def queue
      @queue ||= Roger.channel.queue('', exclusive: true)
    end

    def exchange
      @exchange ||= Roger.channel.exchange(Config.rpc_route_name, type: :direct, auto_delete: true)
    end

    def message_id
      @message_id ||= SecureRandom.uuid
    end
  end
end
