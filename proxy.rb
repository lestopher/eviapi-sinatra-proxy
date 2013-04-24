#!/usr/bin/env ruby
require_relative 'lib/sinproxy.rb'

# $1 - endpoint
# $2 - debug
if ARGV.length > 0
  SinProxy.endpoint = ARGV.first
end

SinProxy.run! do |server|
  ssl_options = {
    :cert_chain_file => './ssl/default.cer',
    :private_key_file => './ssl/default.key',
    :verify_peer => false
  }
  server.ssl = true
  server.ssl_options = ssl_options
end
