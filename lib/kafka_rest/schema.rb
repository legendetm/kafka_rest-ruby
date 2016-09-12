require 'base64'

module KafkaRest
  class Schema
    attr_accessor :id

    def schema_string
      raise NotImplementedError
    end

    def content_type
      raise NotImplementedError
    end

    def serializer
      raise NotImplementedError
    end

    def decode_message(message)
      raise NotImplementedError
    end
  end

  class AvroSchema < Schema
    attr_reader :schema

    def initialize(id: nil, schema: nil)
      if !id && !schema
        raise ArgumentError, 'Either schema id or schema string must be set'
      elsif id && !id.is_a?(Integer)
        raise ArgumentError,  'Avro schema id must be an Integer'
      elsif schema && !schema.is_a?(String)
        e = 'Avro schema string must be a json object serialized as a string'
        raise ArgumentError, e
      end

      @id, @schema = id, schema
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

    def serializer
      -> (message) { JSON.load(message) }
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

    def serializer
      -> (message) { Base64.strict_encode64(message) }
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

    def serializer
      -> (message) { JSON.load(message) }
    end
  end
end

