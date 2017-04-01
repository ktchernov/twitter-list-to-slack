require 'oauth'
require 'json'
require 'httparty'
require 'highline/import'
require_relative 'lib/credentials'

credentials = load_credentials
thing_to_say = ARGV[0]

confirm = ask("Send \"#{thing_to_say}\" to the configured Slack channel? [y/n] ") {
  |yn| yn.limit = 1, yn.validate = /[yn]/i
}
exit unless confirm.downcase == 'y'

HTTParty.post credentials['slack_webhooks_uri'], {
    :body => {
        :text => thing_to_say
    }.to_json,
    :headers => {'Content-Type' => 'application/json'}
}

puts "Sent #{thing_to_say}"
