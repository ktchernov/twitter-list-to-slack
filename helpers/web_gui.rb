# This file provides a web front end for the bot (e.g. can be used with Heroku)

require 'sinatra.rb'
require_relative '../lib/history'

history = History.new(url: ENV['KB_REDIS_URL'], prefix: ENV['KB_REDIS_PREFIX'])

get '/' do
  "Last emitted id " + history.load_latest_emitted_id.to_s
end
