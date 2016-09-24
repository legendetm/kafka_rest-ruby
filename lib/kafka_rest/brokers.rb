module KafkaRest
  class Brokers
    attr_accessor :brokers
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def list
      broker_ids = client.request(:get, '/brokers')[:brokers]
      brokers = broker_ids.map do |broker_id|
        Broker.new(broker_id)
      end
    end
  end

  class Broker
    attr_reader :id

    def initialize(id)
      @id = id
    end

    def to_s
      "Broker #{id}"
    end
  end
end
