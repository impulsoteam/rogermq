#!/usr/bin/env gem build
# encoding: utf-8

require 'base64'
require File.expand_path('../lib/roger/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'roger'
  s.version = Roger::VERSION.dup
  s.summary = 'RabbitMQ client for easy topic and rpc'
  s.description = 'RabbitMQ queues and rpc made easy'
  s.authors = %w[lsantosc@gmail.com cavallari@live.com]
  s.executables = ['roger']
  s.files = Dir['lib/**/*']
  s.add_dependency 'dotenv'
  s.add_dependency 'bunny', '~> 2.17.0'
end
