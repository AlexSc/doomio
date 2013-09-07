require 'sinatra'
require 'base64'
require 'lib/orchestrate'

class Doomio < Sinatra::Application
  enable :sessions

  before do
    @orchestrate = Orchestrate.new(ENV["ORCHESTRATE_IO_API_KEY"])
  end

  get '/' do
    if session[:user_id] && (@user = @orchestrate.kv_get("users", session[:user_id]))
      @user["last_login"] = Time.now.to_i
      @orchestrate.kv_put("users", session[:user_id], @user)
      redirect '/dashboard'
    else
      erb :index
    end
  end

  post '/login' do
    payload = params[:signed_request].split('.')[1]
    payload = JSON.parse(Base64.decode64(payload.gsub('-', '+').gsub('_', '/')))
    user_id = payload["user_id"]
    @user = @orchestrate.kv_get("users", user_id)
    if !@user
      @orchestrate.kv_put("users", user_id, {last_login: Time.now.to_i, created_at: Time.now.to_i})
    end
    session[:user_id] = user_id
    redirect '/dashboard'
  end

  get '/dashboard' do
    erb :dashboard
  end
end
