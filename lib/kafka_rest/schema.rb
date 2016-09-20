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

  class Schema
    attr_accessor :id, :schema_string

    def content_type
      FORMAT_TO_CONTENT_TYPE[format]
    end

    def format
      raise NotImplementedError
    end

    def from_kafka(value)
      value
    end

    def to_kafka(value)
      value
    end

    # Give a nice massage to put the schemas in happy mode
    def self.massage(key_schema: nil, value_schema: nil)
      # If a key schema is provided, a value schema must have been provided
      if key_schema && value_schema.class != key_schema.class
        raise ArgumentError, 'Key and value schema must be the same type'
      end

      # Use the value schema to determine total schema
      value_schema, key_schema = case value_schema
      when NilClass then [BinarySchema.new, BinarySchema.new]
      when AvroSchema
        [value_schema, (key_schema ? key_schema : Schema.new)]
      when BinarySchema
        [value_schema, (key_schema ? key_schema : BinarySchema.new)]
      when JsonSchema
        [value_schema, (key_schema ? key_schema : Schema.new)]
      else raise ArgumentError, "Value schema #{value_schema} not recognized"
      end
    end
  end

  class AvroSchema < Schema
    def initialize(schema = nil, id: nil)
      if !id && !schema
        raise ArgumentError, 'Either schema id or schema string must be set'
      elsif id && !id.is_a?(Integer)
        raise ArgumentError,  'Avro schema id must be an Integer'
      elsif schema && !schema.is_a?(String)
        e = 'Avro schema string must be a json object serialized as a string'
        raise ArgumentError, e
      end

      @id, @schema_string = id, schema
    end

    def format
      Format::AVRO
    end
  end

  class BinarySchema < Schema
    def format
      Format::BINARY
    end

    def to_kafka(value)
      Base64.strict_encode64(value)
    end

    def from_kafka(value)
      Base64.strict_decode64(value)
    end
  end

  class JsonSchema < Schema
    def format
      Format::JSON
    end
  end
end
