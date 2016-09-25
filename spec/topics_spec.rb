require 'spec_helper'

describe KafkaRest::Topics, :vcr do
  let(:client) { kafka_rest_client }
  let(:topics_api) { described_class.new(client) }

  describe '#list' do
    subject { topics_api.list }

    it 'returns the set of topics' do
      expect(subject.length).to eq(1)
      expect(subject.first.name).to eq(TEST_TOPIC)
    end
  end
end

describe KafkaRest::Topic, :vcr do
  let(:client) { kafka_rest_client }
  let(:topic) { described_class.new(client, TEST_TOPIC) }

  describe '#get' do
    subject { topic.get }

    it 'returns topic metadata' do
      expect(subject.configs).to be_empty
      expect(subject.partitions.length).to eq(1)
    end
  end

  describe '#produce_batch' do
    subject do
      topic.produce_batch([
        KafkaRest::Message.new(key: 'sup', value: 'dawg', partition: 0),
        KafkaRest::Message.new(key: nil, value: 'dawg')
      ])
    end

    it 'returns partition and offset metadata for each message' do
      expect(subject.key_schema_id).to be(nil)
      expect(subject.value_schema_id).to be(nil)

      message1 = subject.offsets.first
      expect(message1.partition).to be(0)
      expect(message1.offset).to be(0)

      message2 = subject.offsets.last
      expect(message2.partition).to be(0)
      expect(message2.offset).to be(1)
    end
  end
end
