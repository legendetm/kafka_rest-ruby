describe KafkaRest::Client, :vcr do
  let(:client) { kafka_rest_client }

  describe '#produce' do
    let(:key_schema) do
      KafkaRest::AvroSchema.new('{"name":"ExampleType","type":"int"}')
    end
    let(:value_schema) do
      KafkaRest::AvroSchema.new({
        name: 'ExampleRecord',
        type: "record",
        fields: [{name: 'id', type: "int"}]
      })
    end

    subject do
      client.produce(
        TEST_TOPIC,
        KafkaRest::Message.new(key: 12345, value: {id: 3}),
        value_schema: value_schema,
        key_schema: key_schema
      )
    end

    it 'returns offset metadata for the message' do
      expect(subject.key_schema_id).to eq(1)
      expect(subject.value_schema_id).to eq(2)
      expect(subject.offsets.length).to eq(1)

      message = subject.offsets.first
      expect(message.offset).to eq(0)
      expect(message.partition).to eq(0)
    end
  end
end
