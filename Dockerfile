FROM blueapron/ruby:2.3.3-minideb 

LABEL maintainer engineering@blueapron.com

RUN mkdir /opt/kafka_rest-ruby
WORKDIR /opt/kafka_rest-ruby

ARG GEMFURY_TOKEN

COPY Gemfile kafka-rest.gemspec /opt/kafka_rest-ruby/
RUN ["bundle", "install"]

COPY . /opt/kafka_rest-ruby/

ARG GIT_COMMIT
ENV GIT_COMMIT ${GIT_COMMIT}
