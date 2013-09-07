require 'sinatra'
require 'base64'
require 'securerandom'
require 'lib/orchestrate'
require 'chronic'

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
    if !session[:user_id]
      redirect '/'
    end
    @user = @orchestrate.kv_get("users", session[:user_id])
    if !@user["share_id"]
      @user["share_id"] = SecureRandom.uuid
      @orchestrate.kv_put("users", session[:user_id], @user)
      @orchestrate.kv_put("shares", @user["share_id"], {user_id: session[:user_id]})
    end
    @clocks = @orchestrate.graph_get("users", session[:user_id], "owns")["results"] || []
    erb :dashboard
  end

  post '/clocks' do
    content_type :json
    clock_id = SecureRandom.uuid
    time = Chronic.parse(params[:time])
    if !time
      halt 400, {error: "Invalid Time"}.to_json
    end
    if !params[:title]
      halt 400, {error: "Title is required"}.to_json
    end
    clock = {title: params[:title], end_time: time.to_i, owner: session[:user_id]}
    @orchestrate.kv_put("clocks", clock_id, clock)
    @orchestrate.graph_put("users", session[:user_id], "owns", "clocks", clock_id)
    halt 200, clock.merge({id: clock_id}).to_json
  end

  get '/shares/:id' do
    share = @orchestrate.kv_get("shares", params[:id])
    clocks = @orchestrate.graph_get("users", share["user_id"], "owns")["results"] || []
    erb :shares
  end
end
