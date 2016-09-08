module KafkaRest
  module Producer

    Response = Struct.new(:key_schema_id, :value_schema_id, :offsets)

    def produce(records, value_schema: nil, key_schema: nil, format: nil)
      case format
      when Format::BINARY then produce_binary(records)
      when Format::AVRO produce_avro(records, value_schema, key_schema)
      when Format::JSON then produce_json(records)
      else raise ArgumentError, "Serialization format #{format} not recognized"
      end
    end

    def produce_binary(records)
      body = { records: records.map(&:as_binary) }
      response = client.request(:post, path, body: body, content_type: KafkaRest::Client::BINARY_CONTENT_TYPE)
      parse_response(response, records)

      Response.new(nil, nil, records)
    end

    def produce_avro(records, value_schema, key_schema)
      raise NotImplementedError
    end

    def produce_json(records)
      body = { records: records.map(&:as_json) }
      response = client.request(:post, path, body: body, content_type: KafkaRest::Client::JSON_CONTENT_TYPE)
      parse_response(response, records)

      Response.new(nil, nil, records)
    end

    def parse_response(response, records)
      response.fetch(:offsets).each_with_index do |offset, index|
        record = records[index]

        record.topic = topic.name
        if offset.key?(:error)
          record.offset    = offset.fetch(:offset)
          record.partition = offset.fetch(:partition)
        else
          record.error      = offset.fetch(:error)
          record.error_code = offset.fetch(:error_code)
        end
      end
    end
  end
end
