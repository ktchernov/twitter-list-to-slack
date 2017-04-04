# Cloud Setup

If hosting the script with a cloud provider (such as Heroku), credentials and other parameters could be configured through environment variables instead of a credentials file. Instead of using local storage for history, Redis should be configured (local storage typically will not work on Cloud providers).

### Crediential Environment Variables

| Variable | Value |
| ------------- | ------------- |
| KB_CONSUMER_KEY | Twitter API Consumer Key  |
| KB_CONSUMER_SECRET | Twitter API Consumer Secret |
| KB_TOKEN | Twitter Access Token |
| KB_SECRET | Twitter Access Token Secret|
| KB_SLACK_WEBHOOKS_URI | Slack WebHooks API |
| KB_REDIS_URL | URL for a Redis service provider* |

*=Redis is used to store the history of the last emitted tweet. Free providers such as Redis To Go are available with Heroku.

### Timed job

The optional helper `time_guarded_run.rb` can be used to schedule jobs. For example, Heroku's basic timer allows a script to be triggered every hour without specifying the time of day. The helper script will filter by time of day. It can be configured with these optional values (defaults are used otherwise):

| Variable | Value |
| ------------- | ------------- |
| KB_WEEKDAY_ONLY | If true the bot will only emit Tweets on Weekdays (default is true) |
| KB_START_HOUR, KB_END_HOUR | Tweets will only be emitted when the script is called between these hours |
| KB_MAX_TWEETS | Maximum tweets to emit |
