module KafkaRest
  module Producer

    Response = Struct.new(:key_schema_id, :value_schema_id, :offsets)
    Offset = Struct.new(:partition, :offset, :error_code, :error)

    def produce(messages, value_schema: nil, key_schema: nil)
      # If a key schema is provided, a value schema must have been provided
      if key_schema && value_schema.class != key_schema.class
        raise ArgumentError, 'Key and value schema must be the same type'
      end

      # Use the value schema to determine total schema
      value_schema, key_schema = case value_schema
      when NilClass then [BinarySchema.new, BinarySchema.new]
      when AvroSchema
        [value_schema, (key_schema ? key_schema : AvroSchema.new)]
      when BinarySchema
        [value_schema, (key_schema ? key_schema : BinarySchema.new)]
      when JsonSchema
        [value_schema, (key_schema ? key_schema : JsonSchema.new)]
      else raise ArgumentError, "Value schema #{value_schema} not recognized"
      end

      encoded_messages = Array(messages).map do |message|
        {
          key: message.key ? key_schema.serializer.call(message.key) : nil,
          value: message.value ? value_schema.serializer.call(message.value) : nil,
          partition: message.partition
        }
      end
      body = { records: encoded_messages }
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
