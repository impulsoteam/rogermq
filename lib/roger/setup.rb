module Roger
  class Setup
    class << self
      include Roger::Logging

      def start
        load_rails
        Roger.load_consumers
        Roger.broker.start
        logger.info '[ i ] Starting Consumers'
        map_routes
      end

      def stop
        logger.info '[ i ] Quitting Roger'
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

      def map_routes
        Roger.routes.each do |key, route|
          Roger.queues[route.queue] ||= Roger.channel.queue(route.queue, route.route_params)
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
    end
  end
end
