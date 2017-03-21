describe KafkaRest::Client do
  let(:client) { kafka_rest_client }

  describe '#produce', :vcr do
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

  describe '#request' do
    subject { client.request(:get, '/example/path') }

    before do
      allow(client.http).to receive(:request) { response }
    end

    let(:response) do
      Net::HTTPInternalServerError.new('1.1', '500', 'Internal Server Error')
    end

    describe 'failure from kafka rest proxy' do
      before do
        response['Content-Type'] = 'application/vnd.kafka'
        response.body = JSON.dump({error_code: 50002, message: 'Kafka Error'})
        response.instance_variable_set('@read', true)
      end

      it 'raises Kafka Rest Kafka Error' do
        expect { subject }.to raise_error(KafkaRest::KafkaError, /50002 Kafka Error/)
      end
    end

    describe 'failure from load balancer' do
      it 'raises a generic HTTP error' do
        expect { subject }.to raise_error(Net::HTTPFatalError, /500 "Internal Server Error"/)
      end
    end
  end
end
