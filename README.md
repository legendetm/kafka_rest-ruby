# Kafka REST Proxy Ruby Client

Ruby client for Confluent Inc.'s Kafka REST Proxy, which implements a commonly used subset of Kafka client actions over HTTP.

## Installation

This gem is not yet available on our internal Gemfury account, so you will need to add to your `Gemfile`:

```ruby
gem 'kafka_rest', git: 'https://github.com/blueapron/kafka_rest-ruby', branch: 'master'
```

## Usage

### Construct a client

```ruby
require 'kafka_rest'

# Specify location of Kafka REST Proxy as HTTPS endpoint, auth,
# and any additional headers to be sent with the HTTP requests
client = KafkaRest::Client.new(
  'https://kafka-rest-proxy.b--a.com',
  username = 'confluent', password = 'REDACTED',
  'Host' => '/kafka-utils/confluent-rest-proxy'
)
```

### Topics

```ruby
# List topics
client.topics.list

# Get topic metadata
topic = client.topic('some-topic')
topic.get

# Produce empty messages to a topic
topic.produce(KafkaMessage.new)
topic.produce_batch([KafkaMessage.new, KafkaMessage.new])
```

### Partitions

```ruby
# Retrieve a reference for a given partition
partition = topic.partition(0)
# Fetch metadata for partition
partition.get

# Produce empty messages to a partition
partition.produce(KafkaMessage.new)
partition.produce_batch([KafkaMessage.new, KafkaMessage.new])

# List partitions for a topic
topic.get && topic.partitions
# OR:
KafkaRest::Partitions.new(client, topic).list

# Consume a single message from the beginning of the partition
messages = partition.consume(offset: 0)
# Consume 10 messages from the middle of the partition
partition.consume(count: 10, offset: 10) do |message|
  puts message.key, message.value
end
```

### Messages and schemas

```ruby
# Messages can be published in the default binary (data must be a string),
# or in Avro/JSON format. In this case, data can be anything that responds to
# `to_json`, but preferably a hash of some sort.

# Binary style
message = KafkaMessage.new(key: 'serialize', value: 'binary')
client.produce('binary-topic', message)

# Json style
message = KafkaMessage.new(
  key: {order: 123},
  value: {type: "Meal Picker", products_from: [1, 2], products_to: [3, 4]}
)
client.produce(message,
  key_schema: KafkaRest::JsonSchema.new,
  value_schema: KafkaRest::JsonSchema.new
)

# Avro style
key_schema = {
  name: "OrderId",
  type: "record",
  fields: [{name: "order", type: "int"}]
}
value_schema = {
  name: "MealPickerEvent",
  type: "record",
  fields: [
    {name: "type", type: "string"},
    {name: "products_from", type: "array", items: "int"},
    {name: "products_to", type: "array", items: "int"},
  ]
}
client.produce(message,
  key_schema: KafkaRest::AvroSchema.new(key_schema)
  value_schema: KafkaRest::AvroSchema.new(value_schema)
)
```

### Consumers

```ruby
# Construct a consumer instance in a consumer group
# "smallest" consumes from beginning of topic,
# "largest" (default), consumes only messages from the latest offset commit
consumer = client.consumers('test-consumer-group').create(
  'test-consumer-instance'
  "auto.offset.reset": "smallest",
  format: KafkaRest::Format::AVRO
)

# Methods for consuming messages
messages = client.consume(
  'avro-topic',
  key_schema: key_schema,
  value_schema: value_schema
)
client.consume('binary-topic') do |message|
  puts message.key, message.value
end

# Commit offsets for the given consumer instance
# The consumer instance will consume messages from this point
client.commit_offsets
client.destroy
```

### Brokers

```ruby
client.brokers.list
```
