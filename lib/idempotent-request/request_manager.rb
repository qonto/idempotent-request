module IdempotentRequest
  class RequestManager
    attr_reader :request, :storage

    def initialize(request, config)
      @request = request
      @storage = config.fetch(:storage)
      @callback = config[:callback]
    end

    def read
      status, headers, response = parse_data(storage.read(key)).values

      return unless status
      run_callback(:detected, key: request.key)
      [status, headers, response]
    end

    def write(*data)
      status, headers, response = data
      response = response.body if response.respond_to?(:body)
      return data unless (200..226).include?(status)
      storage.write(key, payload(status, headers, response))
      data
    end

    private

    def parse_data(data)
      return {} if data.to_s.empty?

      Oj.load(data)
    end

    def payload(status, headers, response)
      Oj.dump({
        status: status,
        headers: headers.to_h,
        response: response
      })
    end

    def run_callback(action, args)
      return unless @callback

      @callback.new(request).send(action, args)
    end

    def key
      request.key
    end
  end
end
