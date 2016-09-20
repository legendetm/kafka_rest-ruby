module KafkaRest
  module Producer

    Response = Struct.new(:key_schema_id, :value_schema_id, :offsets)
    Offset = Struct.new(:partition, :offset, :error_code, :error)

    def produce(message, value_schema: nil, key_schema: nil)
      produce_batch([message], value_schema: value_schema, key_schema: key_schema)
    end

    def produce_batch(messages, value_schema: nil, key_schema: nil)
      value_schema, key_schema = Schema.massage(
        value_schema: value_schema,
        key_schema: key_schema
      )
      converted_messages = messages.map do |message|
        message.to_kafka(value_schema: value_schema, key_schema: key_schema)
      end

      body = { records: converted_messages }
      if key_schema.id
        body[:key_schema_id] = key_schema.id
      else
        body[:key_schema] = key_schema.schema_string
      end
      if value_schema.id
        body[:value_schema_id] = value_schema.id
      else
        body[:value_schema] = value_schema.schema_string
      end
      response = client.request(:post, path, body: body, content_type: value_schema.content_type)
      parse_response(response)
    end

    def parse_response(response)
      puts response
      offsets = response.fetch(:offsets).map do |offset|
        o = Offset.new
        if offset[:error]
          o.error = offset.fetch(:error)
          o.error_code = offset.fetch(:error_code)
        else
          o.offset = offset.fetch(:offset)
          o.partition = offset.fetch(:partition)
        end
        o
      end
      Response.new(response[:key_schema_id], response[:value_schema_id], offsets)
    end
  end
end
