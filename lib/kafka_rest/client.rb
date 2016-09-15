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
      Topics.new(self).topic(name)
    end

    def brokers
      Brokers.new(self).list
    end

    def consumer(group, options = {})
      KafkaRest::Consumer.new(self, group, options)
    end

    def http
      @http ||= begin
        http = Net::HTTP.new(endpoint.host, endpoint.port)
        http.use_ssl = endpoint.scheme == 'https'
        http
      end
    end

    def close
      finish if http.started?
    end

    def request(method, path, body: nil, content_type: nil, accept: nil)
      request_class = case method
        when :get;    Net::HTTP::Get
        when :post;   Net::HTTP::Post
        when :put;    Net::HTTP::Put
        when :delete; Net::HTTP::Delete
        else raise ArgumentError, "Unsupported request method"
      end

      request = request_class.new(path, headers)
      request['Accept'] = accept || DEFAULT_ACCEPT_HEADER
      request.content_type = content_type || DEFAULT_CONTENT_TYPE_HEADER
      request.basic_auth(username, password) if username && password
      request.body = JSON.dump(body) if body
      puts request.body

      case response = http.request(request)
      when Net::HTTPSuccess
        puts response
        begin
          if response.body
            puts response.body
            JSON.parse(response.body, symbolize_names: true)
          else
            {}
          end
        rescue JSON::ParserError => e
          raise KafkaRest::InvalidResponse, "Invalid JSON in response: #{e.message}"
        end
      when Net::HTTPForbidden
        message = username.nil? ? "Unauthorized" : "User `#{username}` failed to authenticate"
        raise KafkaRest::UnauthorizedRequest.new(response.code.to_i, message)
      else
        response_data = begin
          JSON.parse(response.body, symbolize_names: true)
        rescue JSON::ParserError => e
          raise KafkaRest::InvalidResponse, "Invalid JSON in response: #{e.message}"
        end

        error_class = RESPONSE_ERROR_CODES[response_data[:error_code]] || KafkaRest::ResponseError
        raise error_class.new(response_data[:error_code], response_data[:message])
      end
    end

    def self.open(endpoint, **kwargs, &block)
      client = new(endpoint, **kwargs)
      block.call(client)
    ensure
      client.close
    end
  end
end
