require 'yaml'

def credentials_from_env
	if ENV['KB_CONSUMER_KEY'] == nil
		return nil
	end

	credentials = {
		'consumer_key' => ENV['KB_CONSUMER_KEY'],
		'consumer_secret' => ENV['KB_CONSUMER_SECRET'],
		'token' => ENV['KB_TOKEN'],
		'secret' => ENV['KB_SECRET'],
		'slack_webhooks_uri' => ENV['KB_SLACK_WEBHOOKS_URI']
	}
end

def load_credentials
  credentials=nil
  begin
  	credentials = YAML.load_file('credentials.yml')
  rescue
  	credentials = credentials_from_env

  	if credentials == nil
  		puts "Please create a credentials.yml or define environment variables " +
  			" following the examples in README.md"
  		exit 1
  	end
  end

  credentials
end
