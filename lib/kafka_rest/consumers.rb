module KafkaRest
  class Consumers
    attr_reader :client, :group

    def initialize(client, group)
      @client, @group = client, group
    end

    def path
      "/consumers/#{group}"
    end

    def default_options
      {
        "auto.commit.enable": "false",
        "auto.offset.reset": "largest",
      }
    end

    def create(name, format = Format::BINARY, options = {})
      body = default_options.merge(options).merge({ name: name, format: format })
      response = client.request(:post, path, body: body)
      instance_id, base_uri = response[:instance_id], response[:base_uri]

      temp_client = Client.new(base_uri, client.username, client.password)
      Consumer.new(temp_client, group, instance_id)
    end
  end

  class Consumer
    attr_reader :client, :group, :format, :instance_id

    Response = Struct.new(:key, :value, :partition, :offset)

    def initialize(client, group, instance_id)
      @client, @group, @instance_id = client, group, instance_id
    end

    def path
      "/consumers/#{group}/instances/#{instance_id}"
    end

    def commit_offsets
      client.request(:post, "#{path}/offsets")
    end

    def destroy
      client.request(:delete, path)
    end

    def subscribe(topic, options = {}, &block)
      loop do
        messages = consume(topic, options)
        messages_fetched = messages.length > 0
        messages.each(&block)
        commit_offsets if messages_fetched
      end
    ensure
      client.close
    end

    def consume(topic, options = {}, &block)
      value_schema, key_schema = Schema.massage(
        value_schema: options[:value_schema],
        key_schema: options[:key_schema]
      )

      response = client.request(:get, "#{path}/topics/#{topic}", accept: value_schema.content_type)
      messages = response.map do |m|
        Message.from_kafka(m, value_schema: value_schema, key_schema: key_schema)
      end

      if block_given?
        messages.each(&block)
      else
        messages
      end
    end
  end
end
