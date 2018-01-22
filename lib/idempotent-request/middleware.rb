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
      storage = RequestManager.new(request, config)
      storage.read || storage.write(*app.call(request.env))
    end

    private

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
