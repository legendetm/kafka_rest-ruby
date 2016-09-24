require 'base64'

module KafkaRest
  module ContentType
    AVRO = 'application/vnd.kafka.avro.v1+json'
    JSON = 'application/vnd.kafka.json.v1+json'
    BINARY = 'application/vnd.kafka.binary.v1+json'
  end

  module Format
    AVRO = 'avro'
    BINARY = 'binary'
    JSON = 'json'
  end

  FORMAT_TO_CONTENT_TYPE = {
    Format::AVRO => ContentType::AVRO,
    Format::BINARY => ContentType::BINARY,
    Format::JSON => ContentType::JSON,
  }

  SchemaPair = Struct.new(:value_schema, :key_schema)

  class Schema
    attr_accessor :id, :schema_string

    def content_type
      FORMAT_TO_CONTENT_TYPE[format]
    end

    def format
      raise NotImplementedError
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
    def initialize(schema)
      schema = schema.to_json if schema.is_a?(Hash)
      if schema.is_a?(String)
        @schema_string = schema
      elsif schema.is_a?(Integer)
        @id = schema
      end
    end

    def format
      Format::AVRO
    end

    def from_kafka(value)
      value
    end

    def to_kafka(value)
      value
    end
  end

  class BinarySchema < Schema
    def format
      Format::BINARY
    end

    def to_kafka(value)
      Base64.strict_encode64(value) if value
    end

    def from_kafka(value)
      Base64.strict_decode64(value) if value
    end
  end

  class JsonSchema < Schema
    def format
      Format::JSON
    end

    def from_kafka(value)
      value
    end

    def to_kafka(value)
      value
    end
  end
end
