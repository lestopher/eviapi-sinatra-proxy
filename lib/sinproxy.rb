require 'sinatra/base'
require 'thin'
require 'eviapi'
require 'base64'
class SinProxy < Sinatra::Base
  @endpoint      = nil # Default value
  @endpoint_port = nil
  @redis         = nil
  @use_redis     = false
  @@CACHE_THESE  = {
    "olap_execute"       => 300,
    "olap_dimension_get" => 300,
    "olap_measure_get"   => 300,
    "sql_quickopen"      => 300,
    "folder_search"      => 3600
  }

  # Getter for endpoint
  def self.endpoint
    @endpoint
  end

  # Setter for endpoint
  def self.endpoint=(val)
    @endpoint = val.match(/\/$/) ? val : val + "/"
  end

  def self.redis
    @redis
  end

  def self.endpoint_port
    @endpoint_port
  end

  def self.use_redis
    @use_redis
  end

  def self.endpoint_port=(val)
    @endpoint_port = val
  end

  def self.redis=(val)
    @redis = val
  end

  def self.use_redis=(val)
    @use_redis = val
  end

  configure :production, :development do
    enable :logging
    enable :static
    mime_type :csv, 'text/csv'
  end

  set :root, File.dirname(__FILE__) + '/../'
  # Shouldn't need to set public folder explicitly
  # set :public_folder, File.dirname('/Users/christophernguyen/Sites/eviapi-sinatra-proxy/public')
  set :show_exceptions, true
  # If we're actively developing against the local awv codebase,
  # need to make sure to always refresh the static files
  set :static_cache_control, [:public, :max_age => 1]


  def self.get_or_post(url, &block)
    get(url, &block)
    post(url, &block)
  end

  def paramToEviapiMethod(method)
    if method.downcase.match(/argos\//)
      method.downcase.gsub!(/\./, '_').gsub!(/argos\//, '')
    else
      method.downcase.gsub!(/\./, '_')
    end
  end

  def createKey(method_name, method_params)
    case method_name
    when "folder_search"
      Base64.encode64("search:" + method_params.to_json)
    when "sql_quickopen"
      Base64.encode64(method_params['UniqueId'] + method_params['JSONData'])
    else 
      Base64.encode64(method_params.to_json)
    end
  end

  not_found do
    "NOPE! 404"
  end

  get_or_post '/debuginfo' do
    "root is set to " + settings.root + "<br />" + "public is set to " + settings.public_folder + "<br/>" + "endpoint is #{SinProxy::endpoint}"
  end

  get_or_post '/?' do
    send_file('./public/index.html')
  end

  get_or_post '/mw/*' do
    method_name     = paramToEviapiMethod(params[:splat].first)
    method_params   = params.reject{ |key, value| key == 'splat' || key == 'captures' }
    client          = Eviapi.client
    client.cookie   = request.cookies.map{ |key, value| "#{key}=#{value}" }.join(';')
    client.endpoint = SinProxy::endpoint
    client.port     = SinProxy::endpoint_port
    cached_data     = nil

    if method_name != nil and client.respond_to? method_name
      if SinProxy::use_redis and @@CACHE_THESE.has_key? method_name
        key = createKey(method_name, method_params)
        cached_data = SinProxy::redis.get(key)
        SinProxy::redis.expire(key, 300) if cached_data
      end
      
      unless cached_data
        # Notice the true we're passing in, we're telling eviapi that we want raw values back, not the json values
        response = client.send(method_name, method_params, true)
      end
    end

    if cached_data
      response_headers = {
        "connection"   => "close",
        "content-type" => "application/json; charset=iso-8859-1",
        "server"       => "evisions, inc. maps https server"
      }

      status  200
      headers response_headers
      body    cached_data
    elsif response
      response_headers = response.env[:response_headers]

      # content-length is messed up for some reason, so we let sinatra handle it
      response_headers.delete "content-length"

      if SinProxy::use_redis and @@CACHE_THESE.has_key? method_name
        key = createKey(method_name, method_params)
        SinProxy::redis.set(key, response.body)
        SinProxy::redis.expire(key, @@CACHE_THESE[method_name])
      end

      status  response.status
      headers response_headers
      body    response.body
    else
      puts 'response is nil'
      not_found
    end
  end

  get_or_post '/ReportFiles/*' do
    # Something like https://evidevjs1.evisions.com/ReportFiles/1234/report.pdf
    send_file SinProxy::endpoint + "ReportFiles/#{params[:captures].first}"
  end
end
