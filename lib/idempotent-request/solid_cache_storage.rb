module IdempotentRequest
  class SolidCacheStorage
    attr_reader :solid_cache, :namespace, :expires_in

    def initialize(solid_cache, config = {})
      @solid_cache = solid_cache
      @namespace = config.fetch(:namespace, 'idempotency_keys')
      @expires_in = config[:expires_in]
    end

    def lock(key)
      write_unless_exist(lock_key(key), Time.now.to_f)
    end

    def unlock(key)
      solid_cache.delete(lock_key(key))
    end

    def read(key)
      solid_cache.read(namespaced_key(key))
    end

    def write(key, payload)
      write_unless_exist(namespaced_key(key), payload)
    end

    private

    def write_unless_exist(key, data)
      options = { unless_exist: true }
      options[:expires_in] = expires_in if expires_in > 0
      Rails.logger.info "Writing key: #{key}, data: #{data}, options: #{options}"
      solid_cache.write(key, data, **options)
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
