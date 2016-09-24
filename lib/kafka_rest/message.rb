module KafkaRest
  class Message
    attr_reader :key, :value, :partition, :offset

    def initialize(opts = {})
      @key, @value = opts[:key], opts[:value]
      @partition, @offset = opts[:partition], opts[:offset]
    end

    def to_kafka(value_schema:, key_schema:)
      {
        key: key ? key_schema.to_kafka(key) : nil,
        value: value ? value_schema.to_kafka(value) : nil,
        partition: partition
      }
    end

    def self.from_kafka(kafka_msg, value_schema:, key_schema:)
      value = value_schema.from_kafka(kafka_msg[:value]) if kafka_msg[:value]
      key = key_schema.from_kafka(kafka_msg[:key]) if kafka_msg[:key]
      partition, offset = kafka_msg[:partition], kafka_msg[:offset]
      new(value: value, key: key, partition: partition, offset: offset)
    end
  end
end
