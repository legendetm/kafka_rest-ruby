module KafkaRest
  class Topics
    attr_reader :client, :topics

    def initialize(client)
      @client = client
    end

    def path
      '/topics'
    end

    def list
      topics = client.request(:get, path)[:topics]
      @topics = topics.map { |t| Topic.new(client, t) }
    end

    def topic(topic_name)
      Topic.new(client, topic_name)
    end
  end

  class Topic
    include KafkaRest::Producer

    attr_reader :client, :configs, :name, :partitions

    def initialize(client, name)
      @client, @name = client, name
      @partitions = Partitions.new(client, self)
    end

    def partition(id)
      KafkaRest::Partition.new(client, self, id)
    end

    def path
      "/topics/#{name}"
    end

    def to_s
      "Topic #{name}"
    end

    def get
      response = client.request(:get, path)
      @configs = response.fetch(:configs)
      @partitions = response.fetch(:partitions).map do |partition|
        Partition.new(client, self, partition.partition, partition)
      end
      self
    end
  end
end
