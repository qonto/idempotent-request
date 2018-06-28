module IdempotentRequest
  class Middleware
    def initialize(app, config = {})
      @app = app
      @config = config
      @policy = config.fetch(:policy)
    end

    def call(env)
      # dup the middleware to be thread-safe
      dup.process(env)
    end

    def process(env)
      set_request(env)
      return app.call(request.env) unless process?
      read_idempotent_request ||
        write_idempotent_request ||
        concurrent_request_response
    end

    private

    def storage
      @storage ||= RequestManager.new(request, config)
    end

    def read_idempotent_request
      storage.read
    end

    def write_idempotent_request
      return unless storage.lock
      storage.write(*app.call(request.env))
    end

    def concurrent_request_response
      [429, {}, []]
    end

    attr_reader :app, :env, :config, :request, :policy

    def process?
      !request.key.to_s.empty? && should_be_idempotent?
    end

    def should_be_idempotent?
      return false unless policy
      policy.new(request).should?
    end

    def set_request(env)
      @env = env
      @request ||= Request.new(env, config)
    end
  end
end
