require 'bunny'

module Roger
  autoload :Config, 'roger/config'
  autoload :Logging, 'roger/logging'
  autoload :Route, 'roger/route'
  autoload :Payload, 'roger/payload'
  autoload :Server, 'roger/server'
  autoload :Consumer, 'roger/consumer'
  autoload :Rpc, 'roger/rpc'
  autoload :RpcConsumer, 'roger/rpc_consumer'
  autoload :RpcRoute, 'roger/rpc_route'

  class << self
    def routes
      @routes ||= {}
    end

    def rpc_routes
      @rpc_routes ||= {}
    end

    def rpc_queue
      @rpc_queue ||= channel.queue('roger.rpc', exclusive: true)
    end

    def rpc_exchange
      @rpc_exchange ||= channel.exchange('roger.rpc', type: :direct, exclusive: true)
    end

    def exchanges
      @exchanges ||= {}
    end

    def queues
      @queues ||= {}
    end

    def broker
      @broker ||= Bunny.new(Config.client_uri)
    end

    def channel
      @channel ||= broker.create_channel
    end

    def load_consumers
      klasses = ::Rails.root.join('app/roger/consumers').glob('**/*.rb')
      klasses.each { |klass| klass.basename(klass.extname.to_s).to_s.camelize.constantize }
    end
  end
end
