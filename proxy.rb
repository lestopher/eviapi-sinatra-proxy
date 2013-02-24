require 'sinatra'
require 'thin'
require 'eviapi'

def self.get_or_post(url, &block)
  get(url, &block)
  post(url, &block)
end

def self.check_method(method)
  Eviapi.respond_to? method
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

get_or_post '/awv' do 
  # my public folder is just a 
  send_file('./public/index.html')
end

get_or_post '/mw/*' do
  method_name   = paramToEviapiMethod(params[:splat][0])
  method_params = params.reject{ |key, value| key == 'splat' || key == 'captures' }
  client        = Eviapi.client
  client.cookie = request.cookies.map{ |key, value| "#{key}=#{value}"}.join(';')

  if method_name != nil and client.respond_to? method_name
    response = client.send(method_name, method_params)
  end

  if response
    header_options = {
      "Cache-Control" => "no-cache", 
      "Connection"    => "close",
      "Content-Type"  => "application/json; charset=ISO-8859-1",
      "Set-Cookie"    => client.cookie
    }
    
    status 200
    headers header_options
    body response.to_json

  else
    puts 'response is nil'
    not_found
  end
end