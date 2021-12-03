require 'sinatra'

set :root, File.expand_path("../..", __FILE__)

get '/' do
  erb :index
end
