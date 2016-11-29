# Kafka REST Proxy Ruby Client

Ruby client for Confluent Inc.'s Kafka REST Proxy, which implements a commonly used subset of Kafka client actions over HTTP.

## Installation

```ruby
gem 'kafka_rest', git: 'https://github.com/blueapron/kafka_rest-ruby'
```

Requires Ruby 2.3+. In order to use the client, you need to get install the [Confluent](http://docs.confluent.io/current/quickstart.html) platform up and running. In addition to following the steps outlined in the documentation, you will also need to start up the Kafka REST Proxy locally. 

```bash
kafka-rest-start
```

Note that you must have Zookeeper, Kafka, and the schema registry running for the rest proxy to work as intended.

## Usage

### Construct a client

```ruby
require 'kafka_rest'

# For testing locally
client = KafkaRest::Client.new('http://localhost:8082')

# In prod/staging, specify location of Kafka REST Proxy as HTTPS endpoint,
# auth, and any additional headers to be sent with the HTTP requests
client = KafkaRest::Client.new(
  'https://kafka-rest-proxy.b--a.com:80',
  username = 'confluent', password = 'REDACTED',
  'Host' => '/kafka-utils/confluent-rest-proxy'
)
```

### Messages and Topics
At the core of Kafka are message and topics. *A message is what* you publish and consume to/from the Kafka broker. It's effectively a key-value pair. Think of this as analogous to a record in a SQL database, except the message is immutable. *A topic is where* you publish/consume messages from. It's mostly analogous to a SQL table. This description is obviously a gross oversimplification, so I advise you to read up on [Kafka](https://kafka.apache.org/documentation#gettingStarted), which you should be doing anyway if you're considering Kafka as a messaging solution. The "1.1 Introduction" and "1.2 Use Cases" sections should be plenty sufficient to understand it at a high level.

```
# Construct a Kafka message
msg1 = KafkaRest::Message.new(key: 'some key', value: 'some value')

# keys and values are both optional
msg2 = KafkaRest::Message.new(value: 'some value')
msg3 = KafkaRest::Message.new(key: 'some key')
msg4 = KafkaRest::Message.new

topic = client.topic('some-random-test-topic')
topic.produce(msg1)
topic.produce_batch([msg1, msg2, msg3, msg4])
```

### Schemas
Every message has two schemas associated to it: one for the key, and one for the schema.
There are three schemas supported: binary (which only supports string and null keys and values), json, and avro.
The default is binary. When you produce a message, which is covered in more depth in the subsequent section, you must specify the schemas.

```ruby
json_schema = KafkaRest::JsonSchema.new
msg = KafkaRest::Message.new(key: 69, value: { user_id: 69, order_id: 420, occurred_at: Time.now.utc })

topic.produce(msg, key_schema: json_schema, value_schema: json_schema)
```

### Messages and schemas
I've documented a use cases for all the schema types here. Note that since binary and json have no imposed structure, constructing those schemas are as simple as calling the initializer with no arguments. However, I encourage you to use [Avro](https://avro.apache.org/docs/current/spec.html) for the structure and evolution components. This constructor takes one argument. It can be a hash (in the case you pass the whole schema), or an integer (in the case where you pass the schema id that's registered with the schema registry)

```ruby
# Messages can be published in the default binary (data must be a string),
# or in Avro/JSON format. In this case, data can be anything that responds to
# `to_json`, but preferably a hash of some sort.

# Binary style
message = KafkaRest::Message.new(key: 'serialize', value: 'binary')
client.produce('binary-topic', message)

# Json style
message = KafkaRest::Message.new(
  key: {order: 123},
  value: {type: "Meal Picker", products_from: [1, 2], products_to: [3, 4]}
)
client.produce('json-topic', message,
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
    {name: "products_from", type: { type: "array", items: "int" } },
    {name: "products_to", type: { type: "array", items: "int" } },
  ]
}
ks = KafkaRest::AvroSchema.new(key_schema)
vs = KafkaRest::AvroSchema.new(value_schema)

client.produce('avro-topic', message, key_schema: ks, value_schema: vs)
```

### Consumers

The producer aspect of Kafka has been quite easy up to this point, consuming is a little more challenging. The nuances go well beyond the scope of this document, so I encourage you to read up on consumer groups in the Kafka documentation before tackling this side of the wall. The short story is that every application that wishes to read from Kafka should *create a single consumer group*. All this means is that the name specified in the consumer group creation method should be constant across the application. You should then *create multiple consumer instances* in a consumer group. Logically, these consumers can exist anywhere. They can exist in the same thread, different threads in the process, or in different processes across different machines. Ultimately, the consumer group name is the thing that ties them all together. The number of consumer instances created is optimally equal to the number of partitions that compose a topic. Any more will not yield any additional parallelism and any less may yield worse performance or an uneven workload across consumers. The names of both the consumer group and the consumer instances need to be unique.

```ruby
# Construct a consumer group
# Make the name constant across your application!
consumer_group = client.consumers('test-consumer-group')

# Construct a consumer to read Avro data
consumer1 = consumer_group.create(
  'test-consumer-instance-1',
  format: KafkaRest::Format::AVRO
)

# In another thread or process, create another consumer
# See details below for what `auto.offset.reset` does
consumer2 = consumer_group.create(
  'test-consumer-instance-2',
  "auto.offset.reset": "smallest",
  format: KafkaRest::Format::AVRO
)

# Methods for consuming messages. You can specify a block which processes
# messages one by one, or retrieve the messages in bulk

messages = consumer1.consume('avro-topic', key_schema: ks, value_schema: vs)
consumer2.consume('avro-topic', key_schema: ks, value_schema: vs) do |message|
  puts message.key, message.value
end

# Commit offsets for the given consumer instance. The consumer instance will
# always consume messages from the last committed offset, so if you forget to
# commit offsets, you will just keep processing the same messages over and over!
# Always remember to commit your offsets!
consumer1.commit_offsets
consumer2.commit_offsets

# Destroy the consumers. This is important to do in your thread shutdown/cleanup hook!
# See discussion below for more in depth details why.
consumer1.destroy
consumer2.destroy
```

Notes and gotchas:

1. Although *consumer groups are persistent*, *consumer instances are transient*. You may be asking then, if the instances are transient, why should I need to call `destroy` on them when my application shuts down? The answer is that the REST proxy does not automatically delete the consumer instances _until they expire_, which is configured by default to be 5 minutes. Expiration occurs when that 5 minute timeout passes without anyone committing offsets for that instance. Always be committing offsets! What that means for your application is that when you restart an app instance (and you didn't call `destroy` on your instances before shutting it down), it will take up to five minutes to begin processing messages again, because the old instances will need to expire before the new instances can start processing messages. If the old instances were properly destroyed during shutdown, the new instances will begin processing messages immediately. Always be destroying dud consumers!

1. `auto.reset.offset` can take the values "smallest" or "largest", with largest being the default. This is really only relevant the first time you set up your application to use Kafka (or if you repartition your topic). All this means is that the consumer instances will start reading from the beginning of the topic, or new messages only. For example, if your topic has a message in it, and you then configure an application to read from Kafka, "largest" will not pick up this message, whereas "smallest" will. Once your application has run once, this option is no longer as important. Choose the one that best fits your needs, although I would recommend sticking with the default of "largest" for production use cases. "smallest" is more useful for local testing.

A sample implementation (likely you will end up using something like Sidekiq instead of constructing a thread manually): 

```ruby
Thread.new do
  begin
    client = KafkaRest::Client.new('http://localhost:8082')
    cg = client.consumers('consumer-group')
    consumer = cg.create('consumer-instance')

    # Continuously consume messages and commit offsets
    loop do
      consumer.consume('test-topic') do |message|
        # Process message here
        puts message.value
      end
      consumer.commit_offsets
    end
  ensure
    # Shutdown hook should destroy consumer instance
    consumer.destroy
  end
end 
```

### Extras

The following methods are for retrieving sections describe methods for retrieving metadata for topics, partitions, and brokers. You generally will not need to use them in your code, but they are available for convenience.

### Topics

```ruby
# List topics
client.topics.list

# Get topic metadata
topic = client.topic('some-topic')
topic.get
```

### Partitions

```ruby
# Retrieve a reference for a given partition
partition = topic.partition(0)
# Fetch metadata for partition
partition.get

# Produce empty messages to a partition
partition.produce(KafkaRest::Message.new)
partition.produce_batch([KafkaRest::Message.new, KafkaRest::Message.new])

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

### Brokers

```ruby
client.brokers.list
```

#### Credits

Originally forked from https://github.com/yagnik/kafka_rest
