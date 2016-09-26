describe KafkaRest::Consumers, :vcr do
  let(:client) { kafka_rest_client }
  let(:consumers_api) { described_class.new(client, TEST_CONSUMER_GROUP) }

  describe '#create' do
    subject do
      consumers_api.create(TEST_CONSUMER_NAME, "auto.offset.reset": "smallest")
    end

    it 'returns a new consumer instance' do
      expect(subject.base_uri).to eq(CLIENT_ENDPOINT + subject.path)
      expect(subject.instance_id).to eq(TEST_CONSUMER_NAME)
    end
  end
end

describe KafkaRest::Consumer, :vcr do
  let(:client) { kafka_rest_client }
  let(:consumer) do
    described_class.new(client, TEST_CONSUMER_GROUP, nil, TEST_CONSUMER_NAME)
  end

  describe '#consume' do
    subject { consumer.consume(TEST_TOPIC) }

    it 'returns the topic messages' do
      expect(subject.length).to eq(2)

      message1 = subject.first
      expect(message1.key).to eq('sup')
      expect(message1.value).to eq('dawg')
      expect(message1.partition).to eq(0)
      expect(message1.offset).to eq(0)

      message2 = subject.last
      expect(message2.key).to be(nil)
      expect(message2.value).to eq('dawg')
      expect(message2.partition).to eq(0)
      expect(message2.offset).to eq(1)
    end
  end

  describe '#commit_offsets' do
    subject { consumer.commit_offsets }

    it 'returns commit metadata for each partition' do
      expect(subject.length).to eq(1)

      commit_metadata = subject.first
      expect(commit_metadata.topic).to eq(TEST_TOPIC)
      expect(commit_metadata.partition).to eq(0)
      expect(commit_metadata.consumed).to eq(1)
      expect(commit_metadata.committed).to eq(1)
    end
  end

  describe '#destroy' do
    subject { consumer.destroy }

    it 'returns no content' do
      expect(subject).to eq({})
    end
  end
end
