module Roger
  class Rpc
    include Roger::Logging

    class TimeoutError < StandardError; end
    class ResponseError < StandardError; end

    attr_reader :target, :lock, :condition, :timeout, :arguments

    def initialize(target, timeout = Config.rpc_timeout)
      @target = target
      @timeout = timeout
      @response = TimeoutError.new('No response from rpc call')
    end

    def call(*arguments)
      @lock = Mutex.new
      @condition = ConditionVariable.new
      @arguments = arguments
      subscribe! && publish!
      lock.synchronize { condition.wait(lock, timeout) }
      queue.delete

      raise @response if @response.is_a?(TimeoutError)
      raise ResponseError.new(@response['result']) unless @response['success']

      @response['result']
    rescue Interrupt
      queue.delete
      logger.info 'Rpc call cancelled'
    end

    private
      def subscribe!
        queue.subscribe do |info, properties, body|
          if properties[:correlation_id] == correlation_id
            @response = JSON.parse(body) rescue body.to_s
            lock.synchronize { condition.signal }
          end
        end
      end

      def publish!
        exchange.publish(
          arguments.to_json,
          routing_key: target,
          reply_to: queue.name,
          correlation_id: correlation_id
        )
      end

      def queue
        @queue ||= App.channel.queue('', exclusive: true)
      end

      def exchange
        @exchange ||= Config.exchange(Config.rpc_channel, type: :direct, auto_delete: true)
      end

      def correlation_id
        @correlation_id ||= SecureRandom.uuid
      end
  end
end
