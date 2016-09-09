module KafkaRest
  class Partitions
    attr_accessor :partitions
    attr_reader :client, :topic

    def initialize(client, topic)
      @client = client
      @topic = topic
    end

    def path
      "/topics/#{topic.name}/partitions"
    end

    def list
      partitions = client.request(:get, path)
      @partitions = partitions.map do |p|
        partition = Partition.new(client, topic, p.partition, p)
      end
    end
  end

  class Partition
    include KafkaRest::Producer

    Replica = Struct.new(:broker, :leader, :in_sync)

    attr_reader :client, :topic, :id, :leader, :replicas

    def initialize(client, topic, id, response = nil)
      @client, @topic, @id = client, topic, id
      populate(response) if response
    end

    def path
      "/topics/#{topic.name}/partitions/#{id}"
    end

    def get
      populate(client.request(:get, path))
      self
    end

    private

    def populate(response)
      @leader   = response.fetch(:leader)
      @replicas = response.fetch(:replicas).map do |r|
        Replica.new(r.fetch(:broker), r.fetch(:leader), r.fetch(:in_sync))
      end
    end
  end
end

