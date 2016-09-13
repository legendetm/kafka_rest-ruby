# KafkaRest [![Build Status](https://travis-ci.org/yagnik/kafka_rest.svg?branch=master)](https://travis-ci.org/yagnik/kafka_rest)

Ruby client for Confluent Inc.'s Kafka rest proxy.

## Usage

### Installation

Add `gem 'kafka_rest'` line to your application's `Gemfile`, and run `bundle install`.

## Creating a client

```ruby
require 'kafka_rest'

client = KafkaRest::Client.new('http://u.wot.m8.com', username = 'confluent', password = 'u wot m8', {'Host' => '/kafka-utils/confluent-rest-proxy'})

# List topics
KafkaRest::Topics.new(client).list

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
schema = KafkaRest::AvroSchema.new(schema: JSON.dump(schema_hash))
message = KafkaRest::Message.new(value: JSON.dump({name: "Nikhil", favorite_number: 2}))
topic.produce(message, value_schema: schema)
```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/kafka_rest/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

