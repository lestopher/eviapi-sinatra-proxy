#!/usr/bin/env ruby
require 'trollop'
require 'redis'
require_relative 'lib/sinproxy.rb'

opts = Trollop::options do
  opt :endpoint, "Your MAPS endpoint", :default => "https://localhost", :short => "e"
  opt :endpoint_port, "MAPS endpoint port", :default => 443, :short => "p"
  opt :redis, "Redis URL", :default => "http://localhost", :short => "r"
  opt :redis_port, "Redis port", :default => 6379, :short => "d"
  opt :sinatra_port, "The port sinatra runs on.", :default => 4567, :short => "o"
  opt :use_redis, :default => false
end

INDEX_FILE = './public/index.html'

SinProxy::endpoint      = opts[:endpoint]
SinProxy::endpoint_port = opts[:endpoint_port]
SinProxy::use_redis     = opts[:use_redis]
SinProxy::redis = Redis.new(:host => opts[:redis], 
                              :port => opts[:redis_port])

# MAPS will look for a timestamped file. For our purposes, we strip it.
if File.exists? INDEX_FILE
  f = File.read(INDEX_FILE)
  replacement = f.gsub(/production\.[0-9]+/, 'production')

  unless f == replacement
    File.open(INDEX_FILE, 'w') { |file| file.puts replacement }
  end
end

SinProxy.run!(:port => opts[:sinatra_port]) do |server|
  ssl_options = {
    :cert_chain_file => './ssl/Default.cer',
    :private_key_file => './ssl/Default.key',
    :verify_peer => false
  }
  server.ssl = true
  server.ssl_options = ssl_options
end
