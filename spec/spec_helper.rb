$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'kafka_rest'
require 'vcr'

CLIENT_ENDPOINT = ENV['KAFKA_REST_PROXY_URI'] || 'http://localhost:8082'
CLIENT_USERNAME = ENV['KAFKA_REST_PROXY_USERNAME']
CLIENT_PASSWORD = ENV['KAFKA_REST_PROXY_PASSWORD']
CLIENT_HEADERS = ENV['KAFKA_REST_PROXY_HEADERS'] || {}

def kafka_rest_client
  Client.new(
    CLIENT_ENDPOINT,
    username: CLIENT_USERNAME,
    password: CLIENT_PASSWORD,
    CLIENT_HEADERS
  )
end

VCR.configure do |config|
  config.configure_rspec_metadata!
  config.default_cassette_options = { serialize_with: :json }
end

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
end
