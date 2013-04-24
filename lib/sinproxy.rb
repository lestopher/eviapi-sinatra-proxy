require 'sinatra'
require 'thin'
require 'eviapi'

class SinProxy < Sinatra::Base
  @endpoint = nil # Default value

  # Getter for endpoint
  def self.endpoint
    @endpoint
  end

  # Setter for endpoint
  def self.endpoint=(val)
    @endpoint = val.match(/\/$/) ? val : val + "/"
  end

  set :public_folder, File.dirname('../public/')
  set :static, true
  # If we're actively developing against the local awv codebase,
  # need to make sure to always refresh the static files
  set :static_cache_control, [:public, :max_age => 1] #if ARGV.length > 1 and ARGV[1] == true

  configure :production, :development do
    enable :logging
  end

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

  not_found do
    "NOPE! 404"
  end

  get_or_post %r{^/argosweb?$}i do
    redirect "#{request.url}/", 301
  end

  get_or_post %r{^/lw?$}i do
    redirect "#{request.url}/", 301
  end

  get_or_post %r{^/lwproto?$}i do
    redirect "#{request.url}/", 301
  end

  get_or_post %r{^/argosweb/?$}i do 
    # my public folder is just a softlink that points elsewhere on my harddrive
    send_file('./public/ArgosWeb/index.html')
  end

  get_or_post %r{^/lw/?$}i do 
    # my public folder is just a softlink that points elsewhere on my harddrive
    send_file('./public/LauncherWeb/index.html')
  end

  get_or_post %r{^/lwproto/?$}i do 
    # my public folder is just a softlink that points elsewhere on my harddrive
    send_file('./public/launcherweb.prototype/index.html')
  end

  get_or_post '/mw/*' do
    method_name     = paramToEviapiMethod(params[:splat].first)
    method_params   = params.reject{ |key, value| key == 'splat' || key == 'captures' }
    client          = Eviapi.client
    client.cookie   = request.cookies.map{ |key, value| "#{key}=#{value}"}.join(';')
    client.endpoint = :endpoint unless :endpoint.nil?

    if method_name != nil and client.respond_to? method_name
      # Notice the true we're passing in, we're telling eviapi that we want raw values back, not the json values
      response = client.send(method_name, method_params, true)
    end

    if response
      response_headers = response.env[:response_headers]

      # content-length is messed up for some reason, so we let sinatra handle it
      response_headers.delete "content-length"

      status  response.status
      headers response_headers
      body    response.body
    else
      puts 'response is nil'
      not_found
    end
  end
end