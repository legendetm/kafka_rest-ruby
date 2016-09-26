require 'logger'

# Borrowed a chunk of this from Sidekiq's logging implementation
module KafkaRest
  module Logging
    class KafkaRestFormatter < Logger::Formatter
      def call(severity, time, program_name, message)
        "#{severity}: #{message}\n"
      end
    end

    def self.initialize_logger(log_target = STDOUT)
      oldlogger = defined?(@logger) ? @logger : nil
      @logger = Logger.new(log_target)
      @logger.level = Logger::INFO
      @logger.formatter = KafkaRestFormatter.new
      oldlogger.close if oldlogger
      @logger
    end

    def self.logger
      defined?(@logger) ? @logger : initialize_logger
    end

    def self.logger=(log)
      @logger = log ? log : Logger.new(File::NULL)
    end
  end
end
