#!/usr/bin/ruby

# This is a simple wrapper designed to be run by an external script.

# It checks to see if the time is within the allowable range for the script to
# run and then calls the main Konstabot script.

time = Time.new
puts "time_guarded_run called at #{time}"

weekday_only = (ENV['KB_WEEKDAY_ONLY'] || 'true') == 'true'
start_hour = (ENV['KB_START_HOUR'] || 8).to_i
end_hour = (ENV['KB_END_HOUR'] || 17).to_i
max_tweets = (ENV['KB_MAX_TWEETS'] || 3).to_i
max_tweets_first_hour = (ENV['KB_MAX_TWEETS_FIRST_HOUR'] || 8).to_i

if weekday_only && (time.saturday? || time.sunday?)
  exit
end

unless time.hour.between? start_hour, end_hour
  exit
end

puts "Running Konstabot with #{max_tweets} max tweets"
system "ruby konstabot.rb -n #{max_tweets}"
