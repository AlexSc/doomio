require 'uri'
require 'json'
require 'httparty'

class Orchestrate
  HEADERS = {'Content-Type' => 'application/json'}.freeze
  def initialize(api_key, version = "v0", endpoint = "https://api.orchestrate.io/")
    @auth = {username: api_key, password: api_key}
    @endpoint = URI.join(endpoint, version).to_s
  end

  def kv_put(collection, key, value)
    response = HTTParty.put("#{@endpoint}/#{collection}/#{key}", body: JSON.generate(value), basic_auth: @auth, headers: HEADERS)
  end

  def kv_get(collection, key)
    response = HTTParty.get("#{@endpoint}/#{collection}/#{key}", basic_auth: @auth, headers: HEADERS)
    if response.code == 404
      nil
    else
      response.parsed_response
    end
  end

  def graph_put(collection, key, relation, collection_b, key_b)
    response = HTTParty.put("#{@endpoint}/#{collection}/#{key}/relations/#{relation}/#{collection_b}/#{key_b}", basic_auth: @auth, headers: HEADERS)
  end

  def graph_get(collection, key, *relations)
    response = HTTParty.get("#{@endpoint}/#{collection}/#{key}/relations?hop=#{relations[0]}", basic_auth: @auth, headers: HEADERS)
  end
end
