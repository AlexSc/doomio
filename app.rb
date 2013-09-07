require 'sinatra'

class Doomio < Sinatra::Application
  get '/' do
    erb :index
  end
end
