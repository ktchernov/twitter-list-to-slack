require 'yaml'
require 'redis'

class History
  KEY_LATEST_EMITTED_ID = 'latest_emitted_id'
  HISTORY_FILE = '../history.yml'

  def initialize(url:, prefix:)
    unless url.nil?
      @redis = Redis.new(:url => url)
      @prefix = prefix
    end
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

  def clear_history
    if @redis.nil?
      begin
        File.delete HISTORY_FILE
      rescue Exception => e
        puts "History file could not be deleted: " + e.to_s
      end

    else
      delete_from_redis
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

  def delete_from_redis
    @redis.del redis_key
  end

  def load_from_redis
    @redis.get redis_key
  end

  def save_to_local(latest_emitted_id)
    updated_history={:latest_emitted_id => latest_emitted_id}

  	File.open(HISTORY_FILE, 'w') { |f| f.write updated_history.to_yaml }
  end

  def save_to_redis(id)
    @redis.set redis_key, id
  end

  def redis_key
    return KEY_LATEST_EMITTED_ID if @prefix.nil?

    "#{@prefix}-#{KEY_LATEST_EMITTED_ID}"
  end
end
