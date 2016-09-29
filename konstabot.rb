require 'oauth'
require 'json'
require 'httparty'
require 'optparse'
require 'yaml'
require 'set'

options = {}
option_parser = OptionParser.new do |opts|
	opts.banner = 'Usage: konstabot.rb [options]'

	opts.on('-n', '--number-of-tweets NUMBER', Integer, 'Number of tweets to emit') do |number|
		options[:number_of_tweets] = number
	end

	opts.on('-d', '--dry-run', 'Log output without posting to Slack') do
		options[:dry_run] = true
	end

	opts.on('-H', '--no-history', 'Ignore the history of the last emitted tweet, scan through all tweets') do
		options[:no_history] = true
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

credentials=nil
begin
	credentials=YAML.load_file('credentials.yml')
rescue
	print 'Please create a credentials.yml following the example in README.md'
	exit 1
end

api_version = '1.1'
api_host = 'api.twitter.com'

config=YAML.load_file('config.yml')

consumer = OAuth::Consumer.new(
		credentials['consumer_key'],
		credentials['consumer_secret'],
		{:site => "https://#{api_host}"}
)

access_token = OAuth::AccessToken.new(consumer, credentials['token'], credentials['secret'])

history=nil
begin
	history=YAML.load_file('history.yml') unless options[:no_history]
rescue
# ignored
end

path_to_query="/#{api_version}/lists/statuses.json?owner_screen_name=#{config['twitter_user']}&slug=#{config['twitter_list']}"
path_to_query+="&since_id=#{history[:latest_emitted_id]}" unless history.nil?
path_to_query+="&include_rts=0&count=#{config['num_tweets_to_fetch']}&include_entities=false"
response=access_token.get(path_to_query)

raise "Failed to get twitter feed: #{resonse.to_s}" unless response.class == Net::HTTPOK

tweets=JSON.parse(response.body)

tweets.select! { |tweet|
	tweet['retweet_count'] >= config['retweet_min_count'] || tweet['favorite_count'] >= config['likes_min_count'] }

# Split out words, compare them to blacklist.
blacklist_set = config['blacklisted_words'].map { |word| word.downcase }
tweets.reject! { |tweet| tweet['text'].split(/[^\w]+/).any? { |word| blacklist_set.member?(word.downcase) } }

tweets.sort! { |tweetA, tweetB|
	tweetB['retweet_count'] + tweetB['favorite_count'] <=> tweetA['retweet_count'] + tweetB['favorite_count']
}

# Same account can only be emitted emit_max_tweets_per_user times per session
if config.key? 'emit_max_tweets_per_user'
	seen_users = {}
	tweets_to_emit = []
	tweets.each { |tweet|
		screen_name = tweet['user']['screen_name']

		seen_users[screen_name] = 0 unless seen_users.key? screen_name
		next if seen_users[screen_name] >= config['emit_max_tweets_per_user']

		seen_users[screen_name]=seen_users[screen_name]+1

		tweets_to_emit << tweet

		break if tweets_to_emit.length == options[:number_of_tweets]
	}
else
	tweets_to_emit = tweets.take options[:number_of_tweets]
end

latest_emitted_id=0

# Send the Tweets to Slack
tweets_to_emit.each { |tweet|
	msg_text = tweet['text']
	user_name = tweet['user']['screen_name']
	id=tweet['id']
	id_str = tweet['id_str']
	icon_url = tweet['user']['profile_image_url_https']

	latest_emitted_id=id if id > latest_emitted_id

	twitter_status_uri = "https://twitter.com/#{user_name}/statuses/#{id_str}"
	if options[:dry_run]
		puts "[#{twitter_status_uri}] #{user_name}: #{msg_text}"
	else
		HTTParty.post credentials['slack_webhooks_uri'], {
				:body => {
						:text => twitter_status_uri,
						:username => "#{user_name} (#{config['bot_name']})",
						:icon_url => icon_url
				}.to_json,
				:headers => {'Content-Type' => 'application/json'}
		}
	end
}

unless options[:dry_run] || options[:no_history] || latest_emitted_id != 0
	updated_history={:latest_emitted_id => latest_emitted_id}

	File.open('history.yml', 'w') { |f| f.write updated_history.to_yaml }
end