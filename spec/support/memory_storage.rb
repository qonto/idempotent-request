module IdempotentRequest
  class MemoryStorage
    def initialize
      @memory = {}
    end

    def lock(key)
      namespaced_key = lock_key(key)
      return false if @memory.key?(namespaced_key)
      @memory[namespaced_key] = true
    end

    def unlock(key)
      namespaced_key = lock_key(key)
      @memory.delete(namespaced_key)
      @memory[namespaced_key]
    end

    def read(key)
      @memory[key]
    end

    def write(key, payload)
      @memory[key] = payload
    end

    def clear
      @memory = {}
    end

    private

    def lock_key(key)
      "lock:#{key}"
    end
  end
end
