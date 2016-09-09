module KafkaRest
  class Brokers
    attr_reader :brokers, :client

    def initialize(client)
      @client = client
    end

    def list
      broker_i = client.request(:get, '/brokers')[:brokers]
      @brokers = brokers.map { |b| Broker.new(b) }
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

