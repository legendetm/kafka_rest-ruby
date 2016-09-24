# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kafka_rest/version'

Gem::Specification.new do |spec|
  spec.name          = "kafka_rest"
  spec.version       = KafkaRest::VERSION
  spec.authors       = ["nikhilofthesouth"]
  spec.summary       = %q{Ruby gem to access kafka-rest by Confluent Inc}
  spec.description   = %q{Ruby gem to access kafka-rest by Confluent Inc}
  spec.homepage      = "http://confluent.io/docs/current/kafka-rest/docs/index.html"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.5"
end
