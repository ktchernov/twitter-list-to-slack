require 'oauth'

class TwitterListReader
  API_VERSION = '1.1'
  API_HOST = 'api.twitter.com'

  def initialize(credentials)
    consumer = OAuth::Consumer.new(
    		credentials['consumer_key'],
    		credentials['consumer_secret'],
    		{:site => "https://#{API_HOST}"}
    )

    @access_token = OAuth::AccessToken.new(consumer, credentials['token'], credentials['secret'])
  end

  def read_list(user:, list:, latest_emitted_id:, num_tweets:)
    path_to_query = "/#{API_VERSION}/lists/statuses.json?owner_screen_name=#{user}&slug=#{list}"
    path_to_query += "&since_id=#{latest_emitted_id}" unless latest_emitted_id.nil?
    path_to_query += "&include_rts=0&count=#{num_tweets}&include_entities=false"
    response = @access_token.get path_to_query

    unless response.class == Net::HTTPOK
      raise "Failed to get twitter feed:\n\t#{response.code}: #{response.body}\n\tfor #{path_to_query}"
    end

    JSON.parse(response.body)
  end
end
