module IdempotentRequest
  class RedisStorage
    attr_reader :redis, :namespace, :expire_time

    def initialize(redis, config = {})
      @redis = redis
      @namespace = config.fetch(:namespace, 'idempotency_keys')
      @expire_time = config[:expire_time]
    end

    def read(key)
      redis.get(namespaced_key(key))
    end

    def write(key, payload)
      redis.setnx(namespaced_key(key), payload)
      redis.expire(namespaced_key(key), expire_time.to_i) if expire_time.to_i > 0
    end

    private

    def namespaced_key(idempotency_key)
      [namespace, idempotency_key.strip]
        .compact
        .join(':')
        .downcase
    end
  end
end
