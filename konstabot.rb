require 'json'
require 'httparty'
require 'optparse'
require 'yaml'
require_relative 'lib/credentials'
require_relative 'lib/history'
require_relative 'lib/twitter_list_reader'
require_relative 'lib/tweet_filter'

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

credentials = load_credentials

config = YAML.load_file('config.yml')

history = History.new(url: ENV['KB_REDIS_URL'])
latest_emitted_id = history.load_latest_emitted_id unless options[:no_history]

list_reader = TwitterListReader.new credentials
tweets = list_reader.read_list(
	user: config['twitter_user'],
	list: config['twitter_list'],
	latest_emitted_id: latest_emitted_id,
	num_tweets: config['num_tweets_to_fetch']
)

tweets_to_emit = filter(
	tweets: tweets,
	config: config,
	max_tweets: options[:number_of_tweets]
)

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

puts "Printed #{tweets_to_emit.length} tweets"

unless options[:dry_run] || options[:no_history] || latest_emitted_id == 0
	history.save_latest_emitted_id latest_emitted_id
end
