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

    def consume(topic, options = {}, &block)
      schema_pair = Schema.to_pair(
        value_schema: options[:value_schema],
        key_schema: options[:key_schema]
      )

      response = client.request(
        :get,
        "#{path}/topics/#{topic}",
        accept: schema_pair.value_schema.content_type)
      messages = response.map do |m|
        Message.from_kafka(m, schema_pair)
      end

      if block_given?
        messages.each(&block)
      else
        messages
      end
    end
  end
end
