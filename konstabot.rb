require 'oauth'
require 'json'
require 'httparty'
require 'optparse'
require 'yaml'

options = {}
option_parser = OptionParser.new do |opts|
	opts.banner = 'Usage: konstabot.rb [options]'

	opts.on('-n', '--number-of-tweets NUMBER', Integer, 'Number of tweets to emit') do |number|
		options[:number_of_tweets] = number
	end

	opts.on('-d', '--dry-run', 'Log output without posting to Slack') do
		options[:dry_run] = true
	end
end

begin
	option_parser.parse!
	mandatory = [:number_of_tweets]
	missing = mandatory.select { |param| options[param].nil? }
	unless missing.empty?
		raise OptionParser::MissingArgument.new(missing.join(', '))
	end
rescue OptionParser::ParseError
	puts $!.to_s # Friendly output when parsing fails
	puts option_parser
	exit 1
end

api_version = '1.1'
api_host = 'api.twitter.com'

config=YAML.load_file('config.yml')

consumer = OAuth::Consumer.new(
		config['consumer_key'],
		config['consumer_secret'],
		{:site => "https://#{api_host}"}
)

access_token = OAuth::AccessToken.new(consumer, config['token'], config['secret'])

response=access_token.get(
		"/#{api_version}/lists/statuses.json?owner_screen_name=k_tcher&slug=android&include_rts=0&count=100&include_entities=false")

exit 1 unless response.class == Net::HTTPOK

tweets=JSON.parse(response.body)

tweets.select! { |tweet| tweet['retweet_count'] >= 4 || tweet['favorite_count'] >= 4 }

tweets.sort! { |b, a| a['retweet_count'] + a['favorite_count'] <=> b['retweet_count'] + b['favorite_count'] }

# Same account can only be emitted 2 times
seen_users = {}
tweets_to_emit = []
tweets.each { |tweet|
	screen_name = tweet['user']['screen_name']

	seen_users[screen_name] = 0 unless seen_users.key? screen_name
	next if seen_users[screen_name] > 1

	seen_users[screen_name]=seen_users[screen_name]+1

	tweets_to_emit << tweet

	break if tweets_to_emit.length == options[:number_of_tweets]
}

for item in tweets_to_emit
	msg_text = item['text']
	user_name = item['user']['screen_name']
	id_str = item['id_str']
	icon_url = item['user']['profile_image_url_https']

	puts "#{user_name}: #{msg_text}"

	unless options[:dry_run]
		HTTParty.post config['slack_webhooks_uri'], {
				:body => {
						:text => "https://twitter.com/#{user_name}/statuses/#{id_str}",
						:username => "#{user_name} (Konstabot)",
						:icon_url => icon_url
				}.to_json,
				:headers => {'Content-Type' => 'application/json'}
		}
	end
end
