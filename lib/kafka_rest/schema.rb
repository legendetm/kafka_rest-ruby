require 'base64'
require 'set'

module KafkaRest
  module ContentType
    AVRO = 'application/vnd.kafka.avro.v2+json'
    JSON = 'application/vnd.kafka.json.v2+json'
    BINARY = 'application/vnd.kafka.binary.v2+json'
  end

  module Format
    AVRO = 'avro'
    BINARY = 'binary'
    JSON = 'json'
  end

  SchemaPair = Struct.new(:value_schema, :key_schema)

  class Schema
    attr_accessor :id, :schema_string

    def content_type
      SCHEMA_TO_CONTENT_TYPE[self.class]
    end

    def from_kafka(value)
      raise NotImplementedError
    end

    def to_kafka(value)
      raise NotImplementedError
    end

    def self.default
      BinarySchema
    end

    def self.from_format(format)
      FORMAT_TO_SCHEMA.fetch(format, default).new
    end

    def self.to_pair(key_schema: nil, value_schema: nil)
      if value_schema && key_schema
        if value_schema.class != key_schema.class
          raise ArgumentError, 'Key and value schema must be the same type'
        end
      elsif value_schema
        key_schema = value_schema.class.new
      elsif key_schema
        value_schema = key_schema.class.new
      else
        key_schema, value_schema = default.new, default.new
      end

      SchemaPair.new(value_schema, key_schema)
    end
  end

  class AvroSchema < Schema
    def initialize(schema = nil)
      if schema.is_a?(Integer)
        @id = schema
      else
        @schema_string = schema.to_json if schema
      end
    end

    def from_kafka(value)
      value
    end

    def to_kafka(value)
      value
    end
  end

  class BinarySchema < Schema
    ALLOWED_TYPES = Set.new([NilClass, String]).freeze

    def to_kafka(value)
      if !ALLOWED_TYPES.include?(value.class)
        raise 'Binary schema only accepts strings/nulls'
      end
      Base64.strict_encode64(value) if value
    end

    def from_kafka(value)
      Base64.strict_decode64(value) if value
    end
  end

  class JsonSchema < Schema
    def from_kafka(value)
      value
    end

    def to_kafka(value)
      value
    end
  end

  SCHEMA_TO_CONTENT_TYPE = {
    AvroSchema => ContentType::AVRO,
    BinarySchema => ContentType::BINARY,
    JsonSchema => ContentType::JSON,
  }

  FORMAT_TO_SCHEMA = {
    Format::AVRO => AvroSchema,
    Format::BINARY => BinarySchema,
    Format::JSON => JsonSchema,
  }
end
