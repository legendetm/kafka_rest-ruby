# Kafka Rest Proxy Ruby Client

Ruby client for Confluent Inc.'s Kafka rest proxy.

## Usage

### Installation

Add `gem 'kafka_rest'` line to your application's `Gemfile`, and run `bundle install`.

## Creating a client

```ruby
require 'kafka_rest'

client = KafkaRest::Client.new('http://u.wot.m8.com', username = 'confluent', password = 'u wot m8', 'Host' => '/kafka-utils/confluent-rest-proxy')

# List topics
client.topics.list

# Create a topic instance
topic = client.topic('test-test-avro1')

schema_hash = {
  :namespace => "example.avro",
  :type => "record",
  :name => "Test",
  :fields => [
    {:name => "name", :type => "string"},
    {:name => "favorite_number", :type => "int"}
  ]
}
schema = KafkaRest::AvroSchema.new(schema_hash)
message = KafkaRest::Message.new(value: {name: "Nikhil", favorite_number: 2})
topic.produce(message, value_schema: schema)
```
