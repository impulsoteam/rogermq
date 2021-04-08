module Roger
  class MessageProcessor
    include Roger::Logging
    attr_reader :info, :properties, :body

    def initialize(info, properties, body)
      @info = info
      @properties = properties
      @body = JSON.parse(body) rescue body.to_s
    end

    def process
      return unless consumer.present?

      if Config.logging.include?(:receives)
        log = ["Received a message in #{queue_name} from #{exchange_name}"]
        log << "through #{routing_key} routing key" if routing_key.present?
        logger.info log.join(' ')
      end

      begin
        response = { success: true, result: consumer.call(method, info, properties, body) }
      rescue => error
        response = { success: false, result: error }
      end

      reply(response) if properties[:reply_to].present?
      raise response[:result] unless response[:success]
    end

    private

    def consumer
      @consumer ||= App.consumers[consumer_key][:klass]
    end

    def method
      @method ||= App.consumers[consumer_key][:method]
    end

    def reply(response)
      App.default_exchange.publish(response.to_json, reply_options)

      if Config.logging.include?(:replies)
        logger.info "Consumer key #{consumer_key} replied to #{properties[:reply_to]}"
      end
    end

    def reply_options
      {
        routing_key: properties[:reply_to],
        correlation_id: properties[:correlation_id],
        app_id: Config.app_id
      }.compact
    end

    def queue_name
      info[:consumer].queue.name
    end

    def exchange_name
      info[:exchange]
    end

    def routing_key
      info[:routing_key]
    end

    def consumer_key
      @consumer_key ||= [exchange_name, queue_name, routing_key].reject(&:blank?).join('.')
    end
  end
end
