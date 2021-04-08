require 'bunny'
require 'securerandom'
require 'json'
require 'active_support/core_ext/string'
require 'active_support/concern'

module Roger
  autoload :App, 'roger/app'
  autoload :Consumer, 'roger/consumer'
  autoload :Config, 'roger/config'
  autoload :Logging, 'roger/logging'
  autoload :MessageProcessor, 'roger/message_processor'
  autoload :Rpc, 'roger/rpc'
end
