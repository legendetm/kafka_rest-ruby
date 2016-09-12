module KafkaRest
  class Message
    attr_reader :key, :value, :partition

    def initialize(key: nil, value: nil, partition: nil)
      @key, @value, @partition = key, value, partition
    end
  end
end
