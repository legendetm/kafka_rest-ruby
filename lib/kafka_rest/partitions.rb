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

    VALID_QUERY_PARAMS = [:count, :offset].freeze

    Replica = Struct.new(:broker, :leader, :in_sync)

    attr_accessor :leader, :replicas
    attr_reader :client, :topic, :id

    def initialize(client, topic, id, response = nil)
      @client, @topic, @id = client, topic, id
      populate(response) if response
    end

    def topic_name
      topic.name
    end

    def path
      "/topics/#{topic_name}/partitions/#{id}"
    end

    def get
      populate(client.request(:get, path))
      self
    end

    def default_options
      {
        count: 1
      }
    end

    def consume(options = {}, &block)
      options = default_options.merge(options)
      KafkaRest.logger.info("Consuming #{options[:count]} messages from topic/partition #{topic_name}/#{id} with offset #{options[:offset]}")

      schema_pair = Schema.to_pair(
        value_schema: options[:value_schema],
        key_schema: options[:key_schema]
      )

      query_params = options.select { |k, v| VALID_QUERY_PARAMS.include?(k) }
      query_string = query_params.map { |k, v| "#{k}=#{v}" }.join('&')
      response = client.request(
        :get,
        "#{path}/messages?#{query_string}",
        accept: schema_pair.value_schema.content_type
      )

      messages = response.map do |m|
        Message.from_kafka(m, schema_pair)
      end

      if block_given?
        messages.each(&block)
      else
        messages
      end
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
