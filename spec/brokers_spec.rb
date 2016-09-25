require 'spec_helper'

describe Brokers, :vcr do
  describe '#list' do
    let(:client) { kafka_rest_client }
    let(:brokers_api) { described_class.new(client) }
    let(:brokers) { brokers_api.list }

    it 'returns the set of brokers' do
      expect(brokers.length).to eq(1)
      expect(brokers.first.id).to eq(0)
    end
  end
end
