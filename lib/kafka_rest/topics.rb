module KafkaRest
  class Topics
    attr_accessor :topics
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def path
      '/topics'
    end

    def list
      tops = client.request(:get, path)
      self.topics = tops.map { |top| Topic.new(client, top) }
    end

    def topic(topic_name)
      Topic.new(client, topic_name)
    end
  end

  class Topic
    include Producer

    attr_accessor :configs, :partitions
    attr_reader :client, :name

    def initialize(client, name)
      @client, @name = client, name
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
      self.configs = response.fetch(:configs)
      self.partitions = response.fetch(:partitions).map do |part|
        Partition.new(client, self, part.partition, part)
      end
      self
    end
  end
end
