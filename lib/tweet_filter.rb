require 'set'

def filter(tweets:, config:, max_tweets:)
  tweets.select! { |tweet|
  	tweet['retweet_count'] >= config['retweet_min_count'] || tweet['favorite_count'] >= config['likes_min_count'] }

  # Split out words, compare them to blacklist.
  blacklist_set = config['blacklisted_words'].map { |word| word.downcase }
  tweets.reject! { |tweet| tweet['text'].split(/[^\w]+/).any? { |word| blacklist_set.member?(word.downcase) } }

  tweets.sort! { |tweetA, tweetB|
  	tweetB['retweet_count'] + tweetB['favorite_count'] <=> tweetA['retweet_count'] + tweetA['favorite_count']
  }

  # Drop responses an sensitive (NSFW) tweets
  tweets.reject! { |tweet| tweet['in_reply_to_user_id_str'] || tweet['possibly_sensitive'] }

  # Same account can only be emitted emit_max_tweets_per_user times per session
  if config.key? 'emit_max_tweets_per_user'
  	seen_users = {}
  	filtered_tweets = []
  	tweets.each { |tweet|
  		screen_name = tweet['user']['screen_name']

  		seen_users[screen_name] = 0 unless seen_users.key? screen_name
  		next if seen_users[screen_name] >= config['emit_max_tweets_per_user']

  		seen_users[screen_name]=seen_users[screen_name]+1

  		filtered_tweets << tweet

  		break if filtered_tweets.length == max_tweets
  	}
  else
  	filtered_tweets = tweets.take max_tweets
  end

  filtered_tweets
end
