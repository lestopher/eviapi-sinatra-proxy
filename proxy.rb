#!/usr/bin/env ruby
require_relative 'lib/sinproxy.rb'

# $1 - endpoint
# $2 - port to run sinatra on
if ARGV.length > 0
  SinProxy.endpoint = ARGV.first
end

port = ARGV[1].nil? ? 4567 : ARGV[1]

SinProxy.run!(:port => port) do |server|
  ssl_options = {
    :cert_chain_file => './ssl/default.cer',
    :private_key_file => './ssl/default.key',
    :verify_peer => false
  }
  server.ssl = true
  server.ssl_options = ssl_options
end
