require 'kafka_rest/version'

module KafkaRest
  InvalidResponse = Class.new(StandardError)
  UnauthorizedRequest = Class.new(StandardError)

  class ResponseError < StandardError
    attr_reader :code

    def initialize(code, message)
      @code = code
      super("#{message} (error code #{code})")
    end
  end

  TopicNotFound = Class.new(ResponseError)
  PartitionNotFound = Class.new(ResponseError)
  ConsumerInstanceNotFound = Class.new(ResponseError)
  LeaderNotAvailable = Class.new(ResponseError)
  ConsumerFormatMismatch = Class.new(ResponseError)
  ConsumerAlreadySubscribed = Class.new(ResponseError)
  ConsumerAlreadyExists = Class.new(ResponseError)
  KeySchemaMissing = Class.new(ResponseError)
  ValueSchemaMissing = Class.new(ResponseError)
  JsonAvroConversionError = Class.new(ResponseError)
  InvalidConsumerConfig = Class.new(ResponseError)
  InvalidSchema = Class.new(ResponseError)
  ZookeeperError = Class.new(ResponseError)
  KafkaError = Class.new(ResponseError)
  KafkaRetriableError = Class.new(ResponseError)
  NoSSLSupport = Class.new(ResponseError)
  NoSimpleConsumerAvailable = Class.new(ResponseError)

  RESPONSE_ERROR_CODES = {
    40401 => TopicNotFound,
    40402 => PartitionNotFound,
    40403 => ConsumerInstanceNotFound,
    40404 => LeaderNotAvailable,
    40601 => ConsumerFormatMismatch,
    40901 => ConsumerAlreadySubscribed,
    40902 => ConsumerAlreadyExists,
    42201 => KeySchemaMissing,
    42202 => ValueSchemaMissing,
    42203 => JsonAvroConversionError,
    42204 => InvalidConsumerConfig,
    42205 => InvalidSchema,
    50001 => ZookeeperError,
    50002 => KafkaError,
    50003 => KafkaRetriableError,
    50101 => NoSSLSupport,
    50301 => NoSimpleConsumerAvailable,
  }

  def self.logger
    KafkaRest::Logging::logger
  end

  def self.logger=(log)
    KafkaRest::Logging::logger = log
  end
end

require 'kafka_rest/logging'
require 'kafka_rest/schema'
require 'kafka_rest/brokers'
require 'kafka_rest/client'
require 'kafka_rest/consumers'
require 'kafka_rest/producer'
require 'kafka_rest/topics'
require 'kafka_rest/partitions'
require 'kafka_rest/message'
