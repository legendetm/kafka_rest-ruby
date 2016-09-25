require 'spec_helper'

describe KafkaRest::Brokers, :vcr do
  let(:client) { kafka_rest_client }
  let(:brokers_api) { described_class.new(client) }

  describe '#list' do
    let(:brokers) { brokers_api.list }

    it 'returns the set of brokers' do
      expect(brokers.length).to eq(1)
      expect(brokers.first.id).to eq(0)
    end
  end
end
