module KafkaRest
  class Consumers
    attr_reader :client, :group

    def initialize(client, group)
      @client, @group = client, group
    end

    def path
      "/consumers/#{group}"
    end

    def create(name, format: nil, options = {})
      body = options.merge({name: name, format: format})
      instance_id = client.request(:post, path, body)[:instance_id]
      Consumer.new(client, group, instance_id) # This needs to be modified so that it can work with DC/OS
    end
  end

  class Consumer
    attr_reader :client, :group, :format, :instance_id, :base_uri

    def initialize(client, group, instance_id, options = {})
      @client, @group, @instance_id, @options = client, group, instance_id, options
    end

    def path
      "/consumers/#{group}/instances/#{instance_id}"
    end

    def commit_offsets
      client.request(:post, "#{path}/offsets")
    end

    def consume(topic, &block)
      messages_fetched, exception_occurred = false, false
      loop do
        messages = fetch_messages(topic)
        messages_fetched ||= messages.length > 0
        messages.each(&block)
      end
    rescue Exception
      exception_occurred = true
      raise
    ensure
      commit if messages_fetched && !exception_occurred
      close
    end

    def fetch_messages(topic)
      response = client.request(:get, "/consumers/#{group}/instances/#{instance_id}/topics/#{topic}", accept: KafkaRest::Client::BINARY_CONTENT_TYPE)
      response.map do |message|
        message[:topic] = topic
        message[:key]   = decode_embedded_format(message[:key])   unless message[:key].nil?
        message[:value] = decode_embedded_format(message[:value]) unless message[:value].nil?
        KafkaRest::Record.new(message)
      end
    end

    def destroy
      client.request(:delete, path)
    end
  end
end
