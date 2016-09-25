require 'spec_helper'

describe KafkaRest::Partitions, :vcr do
  let(:topic_name) { '26494f57-e871-4269-8232-1e0dd83877d8' }
  let(:client) { kafka_rest_client }
  let(:partitions_api) { described_class.new(client, topic_name) }

  describe '#list' do
    let(:partitions) { }
  end
end

describe KafkaRest::Partition, :vcr do
  describe '#produce_batch'
end
