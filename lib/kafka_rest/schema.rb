module KafkaRest
  class Schema
    attr_accessor :id

    def schema_string
      raise NotImplementedError
    end

    def content_type
      raise NotImplementedError
    end

    def decode_message(message)
      raise NotImplementedError
    end
  end

  class AvroSchema < Schema
    attr_reader :schema

    def initialize(schema)
      if !schema.is_a?(String)
        e = 'Avro schema must be a json object serialized as a string'
        raise ArgumentError, e
      end

      @schema = schema
    end

    def schema_string
      schema
    end

    def content_type
      'application/vnd.kafka.avro.v1+json'
    end

    def decode_message(message)
      message
    end
  end

  class BinarySchema < Schema
    def schema_string
      nil
    end

    def content_type
      'application/vnd.kafka.binary.v1+json'
    end

    def decode_message(message)
    end
  end

  class JsonSchema < Schema
    def schema_string
      nil
    end

    def content_type
      'application/vnd.kafka.json.v1+json'
    end

    def decode_message(message)
      message
    end
  end
end

