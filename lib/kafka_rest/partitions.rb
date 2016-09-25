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
      parts = client.request(:get, path)
      self.partitions = parts.map do |part|
        Partition.new(client, topic, part[:partition], part)
      end
    end
  end

  class Partition
    include KafkaRest::Producer

    Replica = Struct.new(:broker, :leader, :in_sync)

    attr_accessor :leader, :replicas
    attr_reader :client, :topic, :id

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
      self.leader = response.fetch(:leader)
      self.replicas = response.fetch(:replicas).map do |r|
        Replica.new(r.fetch(:broker), r.fetch(:leader), r.fetch(:in_sync))
      end
    end
  end
end
