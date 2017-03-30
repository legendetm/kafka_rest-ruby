# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kafka_rest/version'

Gem::Specification.new do |spec|
  spec.name          = "kafka_rest"
  spec.version       = KafkaRest::VERSION
  spec.authors       = ["Blue Apron Engineering"]
  spec.email         = ["engineering@blueapron.com"]
  spec.summary       = %q{Ruby gem to access kafka-rest by Confluent Inc}
  spec.description   = %q{Ruby gem to access kafka-rest by Confluent Inc}
  spec.homepage      = "https://github.com/blueapron/kafka_rest-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 0"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "vcr", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 2.1"
end
