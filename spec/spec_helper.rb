$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'kafka_rest'
require 'vcr'

TEST_TOPIC = "test_kafka_rest_ruby"

CLIENT_ENDPOINT = ENV['KAFKA_REST_PROXY_URI'] || 'http://localhost:8082'
CLIENT_USERNAME = ENV['KAFKA_REST_PROXY_USERNAME']
CLIENT_PASSWORD = ENV['KAFKA_REST_PROXY_PASSWORD']
CLIENT_HEADERS = ENV['KAFKA_REST_PROXY_HEADERS'] || {}

def kafka_rest_client
  KafkaRest::Client.new(
    CLIENT_ENDPOINT,
    CLIENT_USERNAME,
    CLIENT_PASSWORD,
    CLIENT_HEADERS
  )
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
end
