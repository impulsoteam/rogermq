module Roger
  class Setup
    class << self
      def call
        load_rails

        Roger.register_consumers
        Roger.broker.start

        Roger.log '[ i ] Starting Consumers'

        map_exchanges
        bind_queues_to_exchanges
        subscribe_queues

        begin
          sleep(5) while true
        rescue Interrupt
          Roger.log '[ i ] Quitting Roger'
          Roger.broker.close && exit(0)
        end
      end

      private

      def load_rails
        rails_path = File.expand_path(File.join('.', 'config/environment.rb'))

        if File.exist?(rails_path)
          ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || 'development'
          require rails_path
          ::Rails.application.eager_load!
        else
          raise Interrupt
        end
      end

      def map_exchanges
        Roger.routes.each do |route|
          Roger.exchanges["#{route.exchange}"] = Roger.channel.exchange(route.exchange, type: 'topic')
        end
      end

      def bind_queues_to_exchanges
        Roger.routes.each do |route|
          queue = Roger.channel.queue(route.queue, { durable: true, auto_delete: false })
          bind_params = { routing_key: route.routing_key }.compact
          queue.bind(Roger.exchanges[route.exchange], bind_params)

          log = []
          log << "[ i ] [#{route.consumer}] Queue #{route.queue} binds to #{route.exchange}"
          log << "using routing key #{route.routing_key}" if route.routing_key.present?
          Roger.log log.join(' ')

          Roger.queues << [queue, route.consumer]
        end
      end

      def subscribe_queues
        Roger.queues.each do |(queue, consumer)|
          queue.subscribe do |delivery_info, properties, payload|
            Roger.log "[consumer] #{queue.name} received a message"
            payload = Roger::Payload.new(payload, properties, delivery_info)
            consumer.new(payload).process
          end
        end
      end
    end
  end
end
