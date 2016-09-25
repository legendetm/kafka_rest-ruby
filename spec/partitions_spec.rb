require 'spec_helper'

describe KafkaRest::Partitions, :vcr do
  let(:client) { kafka_rest_client }
  let(:topic) { KafkaRest::Topic.new(client, TEST_TOPIC) }
  let(:partitions_api) { described_class.new(client, topic) }

  describe '#list' do
    subject { partitions_api.list }

    it 'returns the partitions for the topic' do
      expect(subject.length).to eq(1)

      partition = subject.first
      expect(partition.id).to eq(0)
      expect(partition.leader).to eq(0)
      expect(partition.replicas.length).to eq(1)

      replica = partition.replicas.first
      expect(replica.broker).to eq(0)
      expect(replica.leader).to be(true)
      expect(replica.in_sync).to be(true)
    end
  end
end

describe KafkaRest::Partition, :vcr do
  let(:client) { kafka_rest_client }
  let(:topic) { KafkaRest::Topic.new(client, TEST_TOPIC) }
  let(:partition) { described_class.new(client, topic, 0) }

  describe '#get' do
    subject { partition.get }

    it 'returns the partition metadata' do
      expect(subject.leader).to eq(0)
      expect(subject.replicas.length).to eq(1)

      replica = subject.replicas.first
      expect(replica.broker).to eq(0)
      expect(replica.leader).to be(true)
      expect(replica.in_sync).to be(true)
    end
  end

  describe '#produce_batch' do
    subject do
      partition.produce_batch([
        KafkaRest::Message.new(key: {id: 3}, value: nil),
        KafkaRest::Message.new(key: nil, value: 'yo')
      ],
      key_schema: KafkaRest::JsonSchema.new,
      value_schema: KafkaRest::JsonSchema.new)
    end

    it 'returns schema, offset, and partition metadata for each message' do
      expect(subject.key_schema_id).to be(nil)
      expect(subject.value_schema_id).to be(nil)
      expect(subject.offsets.length).to eq(2)

      message1 = subject.offsets.first
      expect(message1.partition).to eq(0)
      expect(message1.offset).to eq(0)

      message2 = subject.offsets.last
      expect(message2.partition).to eq(0)
      expect(message2.offset).to eq(1)
    end
  end
end
