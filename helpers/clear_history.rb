require 'highline/import'
require_relative '../lib/history'

confirm = ask("Clear history for #{ENV['KB_REDIS_URL']}\n\twith prefix '#{ENV['KB_REDIS_PREFIX']}'? [y/n] ") {
  |yn| yn.limit = 1, yn.validate = /[yn]/i
}
exit unless confirm.downcase == 'y'

history = History.new(url: ENV['KB_REDIS_URL'], prefix: ENV['KB_REDIS_PREFIX'])

history.clear_history
