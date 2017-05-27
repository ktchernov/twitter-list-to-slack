require 'set'

class TweetFilter

  def initialize(bot_config)
    @bot_config = bot_config
    @blacklist_set = bot_config['blacklisted_words'].map { |word| word.downcase }
    @retweet_weight = @bot_config['retweet_weight'] || 1
  end

  def filter(tweets:, config:)
    tweets = tweets.dup

    if config.key? 'required_word'
      tweets.select! { |tweet| tweet['text'].include? config['required_word']}
    end

    tweets.select! { |tweet|
    	tweet['retweet_count'] >= config['retweet_min_count'] ||
      tweet['favorite_count'] >= config['likes_min_count']
    }

    # Split out words, compare them to blacklist.
    tweets.reject! { |tweet|
      tweet['text'].split(/[^\w]+/).any? { |word|
        @blacklist_set.member?(word.downcase)
      }
    }

    # Drop responses an sensitive (NSFW) tweets
    tweets.reject! { |tweet|
      tweet['in_reply_to_user_id_str'] ||
      tweet['possibly_sensitive']
    }

    tweets
  end

  def pick_best_tweets(tweets:, max_tweets:)
      best_tweets = tweets.dup

      best_tweets.uniq! { |tweet| tweet['id'] }
      best_tweets.sort! { |tweetA, tweetB|
      	tweet_score(tweetB) <=> tweet_score(tweetA)
      }

      best_tweets = cap_per_user best_tweets

      best_tweets.take max_tweets
  end

  def tweet_score(tweet)
      tweet['retweet_count'] * @retweet_weight + tweet['favorite_count']
  end

private

  def cap_per_user(tweets)
    # Same account can only be emitted emit_max_tweets_per_user times per session
    if @bot_config.key? 'emit_max_tweets_per_user'
      seen_users = {}
      filtered_tweets = []
      tweets.each { |tweet|
        screen_name = tweet['user']['screen_name']

        seen_users[screen_name] = 0 unless seen_users.key? screen_name
        next if seen_users[screen_name] >= @bot_config['emit_max_tweets_per_user']

        seen_users[screen_name]=seen_users[screen_name]+1

        filtered_tweets << tweet
      }

      return filtered_tweets
    end

    tweets
  end
end
