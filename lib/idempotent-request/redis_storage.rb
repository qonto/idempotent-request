module IdempotentRequest
  class RedisStorage
    attr_reader :redis, :namespace, :expire_time

    def initialize(redis, config = {})
      @redis = redis
      @namespace = config.fetch(:namespace, 'idempotency_keys')
      @expire_time = config[:expire_time]
    end

    def lock(key)
      setnx_with_expiration(lock_key(key), Time.now.to_f)
    end

    def unlock(key)
      redis.del(lock_key(key))
    end

    def read(key)
      redis.get(namespaced_key(key))
    end

    def write(key, payload)
      setnx_with_expiration(namespaced_key(key), payload)
    end

    private

    def setnx_with_expiration(key, data)
      redis.set(
        key,
        data,
        {}.tap do |options|
          options[:nx] = true
          options[:ex] = expire_time.to_i if expire_time.to_i > 0
        end
      )
    end

    def lock_key(key)
      namespaced_key("lock:#{key}")
    end

    def namespaced_key(key)
      [namespace, key.strip]
        .compact
        .join(':')
        .downcase
    end
  end
end
