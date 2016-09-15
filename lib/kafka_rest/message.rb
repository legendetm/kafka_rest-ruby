require 'base64'

module KafkaRest
  class Message
    attr_accessor :offset
    attr_reader :key, :value, :partition

    def initialize(value:, key: nil, partition: nil)
      @key, @value, @partition = key, value, partition
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
      message = new(value: value, key: key, partition: kafka_msg[:partition])
      message.offset = kafka_msg[:offset]
      message
    end
  end
end
