module Roger
  class Payload
    attr_reader :body, :properties, :delivery_info

    def initialize(body, properties, delivery_info)
      @body = JSON.parse(body) rescue body.to_s
      @properties = properties
      @delivery_info = delivery_info
    end
  end
end
