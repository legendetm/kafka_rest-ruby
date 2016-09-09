module KafkaRest
  class Brokers
    def initialize()
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

