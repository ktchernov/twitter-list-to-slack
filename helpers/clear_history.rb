require_relative '../lib/history'

history = History.new(url: ENV['KB_REDIS_URL'], prefix: ENV['KB_REDIS_PREFIX'])

history.clear_history
