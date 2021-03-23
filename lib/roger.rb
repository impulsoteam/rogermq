require 'bunny'

module Roger
  autoload :Config, 'roger/config'
  autoload :Logging, 'roger/logging'
  autoload :Route, 'roger/route'
  autoload :Consumer, 'roger/consumer'
  autoload :Setup, 'roger/setup'

  class << self
    def routes
      @routes ||= []
    end

    def consumers
      @consumers ||= []
    end

    def queues
      @queues ||= []
    end

    def exchanges
      @exchanges ||= {}
    end

    def broker
      @broker ||= Bunny.new(ENV['CLOUDAMQP_URL'])
    end

    def channel
      @channel ||= @broker.create_channel
    end

    def register_consumers
      klasses = ::Rails.root.join('app/consumers').glob('**/*.rb')
      klasses.each { |klass| consumers << klass.basename(klass.extname.to_s).to_s.camelize.constantize }
    end
  end
end
