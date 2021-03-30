module Roger
  class Server
    class << self
      include Roger::Logging

      def start
        logger.info '[ i ] Starting server'
        load_rails
        Roger.load_consumers
        Roger.broker.start
        start_consumer_routes
        start_rpc_routes
      end

      def stop
        logger.info '[ i ] Stopping server'
        Roger.broker.close
      end

      private

      def load_rails
        rails_path = File.expand_path(File.join('.', 'config', 'environment.rb'))
        raise Interrupt unless File.exist?(rails_path)
        ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || 'development'
        require rails_path
        ::Rails.application.eager_load!
      end

      def start_consumer_routes
        return unless Roger.routes.any?

        Roger.routes.each do |key, route|
          Roger.queues[route.queue] ||= Roger.channel.queue(route.queue, { durable: true, auto_delete: false })
          Roger.exchanges[route.exchange] ||= Roger.channel.exchange(route.exchange, type: 'topic')
          binding_params = { routing_key: route.routing_key }.compact
          Roger.queues[route.queue].bind(Roger.exchanges[route.exchange], binding_params)

          log = ["[ i ] [#{route.consumer}] Queue #{route.queue} binded to #{route.exchange}"]
          log << "using routing key #{route.routing_key}" if route.routing_key.present?
          logger.info log.join(' ')

          Roger.queues[route.queue].subscribe do |info, properties, body|
            consumer_key = [info[:exchange], info[:consumer].queue.name, info[:routing_key]]
              .reject { |c| c.blank? }.join('.')

            payload = Payload.new(body, properties, info)
            Roger.routes[consumer_key].consumer.new(payload).process
          end
        end
      end

      def start_rpc_routes
        return unless Roger.rpc_routes.any?

        Roger.rpc_routes.each do |_, route|
          logger.info "[ i ] [#{route.consumer}] Rpc exchange binded with #{route.routing_key}"
          Roger.rpc_queue.bind(Roger.rpc_exchange, routing_key: route.routing_key)
        end

        Roger.rpc_queue.subscribe do |info, properties, body|
          routing_key = info[:routing_key]
          consumer = Roger.rpc_routes[routing_key].consumer
          body = JSON.parse(body) rescue body

          begin
            payload = Payload.new(nil, properties, info)
            response = { success: true, result: consumer.new(payload).process(*body) }
          rescue => error
            response = { success: false, result: error }
          end

          Roger.rpc_exchange.publish(response.to_json, {
            routing_key: properties[:reply_to],
            correlated_id: properties[:message_id]
          })
        end
      end
    end
  end
end
