require 'yaml'
require 'redis'

class History
  KEY_LATEST_EMITTED_ID = 'latest_emitted_id'
  HISTORY_FILE = 'history.yml'

  def initialize(redis_url: redis_url)
    @redis = Redis.new(:url => redis_url) unless redis_url.nil?
  end

  def load_latest_emitted_id
    if @redis.nil?
      load_from_local
    else
      load_from_redis
    end
  end

  def save_latest_emitted_id(id)
    if @redis.nil?
      save_to_local id
    else
      save_to_redis id
    end
  end

private

  def load_from_local
    begin
    	history = YAML.load_file(HISTORY_FILE)
      history[:latest_emitted_id]
    rescue
      nil
    end
  end

  def load_from_redis
    @redis.get KEY_LATEST_EMITTED_ID
  end

  def save_to_local(latest_emitted_id)
    updated_history={:latest_emitted_id => latest_emitted_id}

  	File.open(HISTORY_FILE, 'w') { |f| f.write updated_history.to_yaml }
  end

  def save_to_redis(id)
    @redis.set KEY_LATEST_EMITTED_ID, id
  end
end
