module KafkaRest
  module Format
    AVRO = 'avro'
    BINARY = 'binary'
    JSON = 'json'
  end

  class Consumers
    attr_reader :client, :group

    def initialize(client, group)
      @client, @group = client, group
    end

    def path
      "/consumers/#{group}"
    end

    def create(name, format = 'binary', options = {})
      body = options.merge({name: name, format: format})
      instance_id = client.request(:post, path, body: body)[:instance_id]
      Consumer.new(client, group, instance_id, options.merge({format: format})) # This needs to be modified so that it can work with DC/OS
    end
  end

  class Consumer
    attr_reader :client, :group, :format, :instance_id, :base_uri

    Response = Struct.new(:key, :value, :partition, :offset)

    def initialize(client, group, instance_id, options = {})
      @client, @group, @instance_id, @options = client, group, instance_id, options
    end

    def path
      "/consumers/#{group}/instances/#{instance_id}"
    end

    def commit_offsets
      client.request(:post, "#{path}/offsets")
    end

    def consume(topic, options = {}, &block)
      messages_fetched, exception_occurred = false, false
      loop do
        messages = fetch_messages(topic, accept, options)
        messages_fetched ||= messages.length > 0
        messages.each(&block)
      end
    rescue Exception
      exception_occurred = true
      raise
    ensure
      commit_offsets if messages_fetched && !exception_occurred
      close
    end

    def fetch_messages(topic, accept, options)
      query_string = if options.any?
        '?' + x.to_a.map { |a| a.join('=') }.join('&')
      else
        ''
      end
      response = client.request(:get, "#{path}/topics/#{topic}#{query_string}", accept: format_to_accept)
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

    def format_to_accept
      case @options[:format]
      when Format::AVRO then ContentType::AVRO
      when Format::BINARY then ContentType::BINARY
      when Format::JSON then ContentType::JSON
      else raise "Unsupported format #{@options[:format]}"
      end
    end
  end
end
