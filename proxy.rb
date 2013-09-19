#!/usr/bin/env ruby
require 'trollop'
require_relative 'lib/sinproxy.rb'
require 'redis'

opts = Trollop::options do
  opt :endpoint, "Your MAPS endpoint", :default => "https://localhost", :short => "e"
  opt :endpoint_port, "MAPS endpoint port", :default => 443, :short => "p"
  opt :redis, "Redis URL", :short => "r"
  opt :redis_port, "Redis port", :short => "d"
  opt :sinatra_port, "The port sinatra runs on.", :default => 4567, :short => "o"
end

INDEX_FILE = './public/index.html'

SinProxy::endpoint      = opts[:endpoint]
SinProxy::endpoint_port = opts[:endpoint_port]

if opts[:redis]
  SinProxy.redis    = Redis.new(:host => opts[:redis], :port => opts[:redis_port] || 6379)
end


# MAPS will look for a timestamped file. For our purposes, we strip it.
if File.exists? INDEX_FILE
  f = File.read(INDEX_FILE)
  replacement = f.gsub(/production\.[0-9]+/, 'production')

  unless f == replacement
    File.open(INDEX_FILE, 'w') { |file| file.puts replacement }
  end
end

puts "sinatra port is #{opts[:sinatra_port]}"
SinProxy.run!(:port => opts[:sinatra_port]) do |server|
  ssl_options = {
    :cert_chain_file => './ssl/default.cer',
    :private_key_file => './ssl/default.key',
    :verify_peer => false
  }
  server.ssl = true
  server.ssl_options = ssl_options
end
