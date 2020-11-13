module IdempotentRequest
  class Middleware
    def initialize(app, config = {})
      @app = app
      @config = config
      @policy = config.fetch(:policy)
      @notifier = ActiveSupport::Notifications if defined?(ActiveSupport::Notifications)
      @conflict_response_status = config.fetch(:conflict_response_status, 429)
    end

    def call(env)
      # dup the middleware to be thread-safe
      dup.process(env)
    end

    def process(env)
      set_request(env)
      request.env['idempotent.request'] = {}
      return app.call(request.env) unless process?
      request.env['idempotent.request']['key'] = request.key
      response = read_idempotent_request || write_idempotent_request || concurrent_request_response
      instrument(request)
      response
    end

    private

    def storage
      @storage ||= RequestManager.new(request, config)
    end

    def read_idempotent_request
      request.env['idempotent.request']['read'] = storage.read
    end

    def write_idempotent_request
      return unless storage.lock
      begin
        result = app.call(request.env)
        request.env['idempotent.request']['write'] = result
        storage.write(*result)
      ensure
        request.env['idempotent.request']['unlocked'] = storage.unlock
        result
      end
    end

    def concurrent_request_response
      status = @conflict_response_status
      headers = { 'Content-Type' => 'application/json' }
      body = [ Oj.dump('error' => 'Concurrent requests detected') ]
      request.env['idempotent.request']['concurrent_request_response'] = true
      Rack::Response.new(body, status, headers).finish
    end

    attr_reader :app, :env, :config, :request, :policy, :notifier

    def process?
      !request.key.to_s.empty? && should_be_idempotent?
    end

    def should_be_idempotent?
      return false unless policy
      policy.new(request).should?
    end

    def instrument(request)
      notifier.instrument('idempotent.request', request: request) if notifier
    end

    def set_request(env)
      @env = env
      @request ||= Request.new(env, config)
    end
  end
end
