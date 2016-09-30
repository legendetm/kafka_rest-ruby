require 'net/http'
require 'json'

module KafkaRest
  class Client
    DEFAULT_ACCEPT_HEADER = 'application/vnd.kafka.v1+json, application/vnd.kafka+json; q=0.9, application/json; q=0.8'
    DEFAULT_CONTENT_TYPE_HEADER = 'application/vnd.kafka.v1+json'

    attr_reader :endpoint, :username, :password, :headers

    def initialize(endpoint, username = nil, password = nil, headers = {})
      @endpoint = URI(endpoint)
      @username, @password = username, password
      @headers = headers
    end

    def topic(name)
      topics.topic(name)
    end

    def topics
      Topics.new(self)
    end

    def brokers
      Brokers.new(self)
    end

    def consumers(group)
      Consumers.new(self, group)
    end

    def http
      @http ||= begin
        http = Net::HTTP.new(endpoint.host, endpoint.port)
        http.use_ssl = endpoint.scheme == 'https'
        http.start
        http
      end
    end

    def close
      http.finish if http.started?
    end

    def request(method, path, opts = {})
      request_class = case method
        when :get;    Net::HTTP::Get
        when :post;   Net::HTTP::Post
        when :put;    Net::HTTP::Put
        when :delete; Net::HTTP::Delete
        else raise ArgumentError, "Unsupported request method"
      end

      request = request_class.new(path, headers)
      request['Accept'] = opts[:accept] || DEFAULT_ACCEPT_HEADER
      request.content_type = opts[:content_type] || DEFAULT_CONTENT_TYPE_HEADER
      request.basic_auth(username, password) if username && password
      request.body = JSON.dump(opts[:body]) if opts[:body]

      case response = http.request(request)
      when Net::HTTPSuccess
        begin
          if response.body
            JSON.parse(response.body, symbolize_names: true)
          else
            {}
          end
        rescue JSON::ParserError => e
          raise InvalidResponse, "Invalid JSON in response: #{e.message}"
        end
      when Net::HTTPForbidden
        message = username.nil? ? "Unauthorized" : "User `#{username}` failed to authenticate"
        raise UnauthorizedRequest.new(response.code.to_i, message)
      else
        response_data = begin
          JSON.parse(response.body, symbolize_names: true)
        rescue JSON::ParserError => e
          raise InvalidResponse, "Invalid JSON in response: #{e.message}"
        end

        error_class = RESPONSE_ERROR_CODES[response_data[:error_code]] || ResponseError
        raise error_class.new(response_data[:error_code], response_data[:message])
      end
    end

    def produce(topic_name, message, opts = {})
      produce_batch(topic_name, [message], opts)
    end

    def produce_batch(topic_name, messages, opts = {})
      topic(topic_name).produce_batch(messages, opts)
    end
  end
end
