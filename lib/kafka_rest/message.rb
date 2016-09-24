module KafkaRest
  class Message
    attr_reader :key, :value, :partition, :offset

    def initialize(opts = {})
      @key, @value = opts[:key], opts[:value]
      @partition, @offset = opts[:partition], opts[:offset]
    end

    def to_kafka(schema_pair)
      {
        key: schema_pair.key_schema.to_kafka(key),
        value: schema_pair.value_schema.to_kafka(value),
        partition: partition
      }
    end

    def self.from_kafka(kafka_msg, schema_pair)
      value = schema_pair.value_schema.from_kafka(kafka_msg[:value])
      key = schema_pair.key_schema.from_kafka(kafka_msg[:key])
      partition, offset = kafka_msg[:partition], kafka_msg[:offset]
      new(value: value, key: key, partition: partition, offset: offset)
    end
  end
end
