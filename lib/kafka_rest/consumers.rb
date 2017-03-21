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
        format: Format::BINARY,
      }
    end

    def create(name, options = {})
      body = default_options.merge(options).merge({ name: name })
      KafkaRest.logger.info("Creating consumer #{name} in group #{group}")

      response, set_cookie = client.request(:post, path, body: body) do |resp|
        [JSON.parse(resp.body, symbolize_names: true), resp.get_fields('Set-Cookie')]
      end
      cookie = Array(set_cookie).map { |sc| sc.split('; ')[0] }.join('; ')
      instance_id, base_uri = response[:instance_id], response[:base_uri]

      headers = {}
      headers['Cookie'] = cookie if !(cookie.nil? || cookie.empty?)
      temp_client = Client.new(base_uri, client.username, client.password, headers)
      Consumer.new(temp_client, group, base_uri, instance_id, format: body[:format])
    end
  end

  class Consumer
    attr_reader :client, :group, :base_uri, :instance_id, :options

    CommitMetadata = Struct.new(:topic, :partition, :consumed, :committed)

    def initialize(client, group, base_uri, instance_id, options = {})
      @client, @group = client, group
      @base_uri, @instance_id = base_uri, instance_id
      @options = options
    end

    def path
      "/consumers/#{group}/instances/#{instance_id}"
    end

    def commit_offsets
      KafkaRest.logger.info("Committing offsets for consumer #{instance_id} in group #{group}")
      client.request(:post, "#{path}/offsets").map do |metadata|
        CommitMetadata.new(
          metadata[:topic],
          metadata[:partition],
          metadata[:consumed],
          metadata[:committed]
        )
      end
    end

    def destroy
      KafkaRest.logger.info("Destroying consumer #{instance_id} in group #{group}")
      client.request(:delete, path)
    ensure
      client.close
    end

    def consume(topic, options = {}, &block)
      KafkaRest.logger.info("Consuming messages from topic #{topic} with consumer #{instance_id} in group #{group}")
      schema = Schema.from_format(self.options[:format])
      schema_pair = Schema.to_pair(value_schema: schema, key_schema: schema)

      response = client.request(
        :get,
        "#{path}/topics/#{topic}",
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
  end
end
