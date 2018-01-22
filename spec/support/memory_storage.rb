module IdempotentRequest
  class MemoryStorage
    def initialize
      @memory = {}
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
  end
end
