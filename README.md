# Idempotent Request [![Build Status](https://travis-ci.org/qonto/idempotent-request.svg?branch=master)](https://travis-ci.org/qonto/idempotent-request)

Rack middleware ensuring at most once requests for mutating endpoints.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'idempotent-request'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install idempotent-request

## How it works

1.  Front-end generates a unique `key` then a user goes to a specific route (for example, transfer page).
2.  When user clicks "Submit" button, the `key` is sent in the header `idempotency-key` and back-end stores server response into redis.
3.  All the consecutive requests with the `key` won't be executer by the server and the result of previous response (2) will be fetched from redis.
4.  Once the user leaves or refreshes the page, front-end should re-generate the key.

## Configuration
```ruby
# application.rb
config.middleware.use IdempotentRequest::Middleware,
  storage: IdempotentRequest::RedisStorage.new(::Redis.current, expire_time: 1.day),
  policy: YOUR_CLASS
```

To define a policy, whether a request should be idempotent, you have to provider a class with the following interface:

```ruby
class Policy
  attr_reader :request

  def initialize(request)
    @request = request
  end

  def should?
    # request is Rack::Request class
  end
end
```

### Example of integration for rails


```ruby
# application.rb
config.middleware.use IdempotentRequest::Middleware,
  storage: IdempotentRequest::RedisStorage.new(::Redis.current, expire_time: 1.day),
  policy: IdempotentRequest::Policy

config.idempotent_routes = [
  { controller: :'v1/transfers', action: :create },
]
```

```ruby
# lib/idempotent-request/policy.rb
module IdempotentRequest
  class Policy
    attr_reader :request

    def initialize(request)
      @request = request
    end

    def should?
      route = Rails.application.routes.recognize_path(request.path, method: request.request_method)
      Rails.application.config.idempotent_routes.any? do |idempotent_route|
        idempotent_route[:controller] == route[:controller].to_sym &&
          idempotent_route[:action] == route[:action].to_sym
      end
    end
  end
end
```


### Use ActiveSupport::Notifications to read events

```ruby
# config/initializers/idempotent_request.rb
ActiveSupport::Notifications.subscribe('idempotent.request') do |name, start, finish, request_id, payload|
  notification = payload[:request].env['idempotent.request']
  if notification['read']
    Rails.logger.info "IdempotentRequest: Hit cached response from key #{notification['key']}, response: #{notification['read']}"
  elsif notification['write']
    Rails.logger.info "IdempotentRequest: Write: key #{notification['key']}, status: #{notification['write'][0]}, headers: #{notification['write'][1]}, unlocked? #{notification['unlocked']}"
  elsif notification['concurrent_request_response']
    Rails.logger.warn "IdempotentRequest: Concurrent request detected with key #{notification['key']}"
  end
end
```

## Custom options

```ruby
# application.rb
config.middleware.use IdempotentRequest::Middleware,
  header_key: 'X-Qonto-Idempotency-Key', # by default Idempotency-key
  policy: IdempotentRequest::Policy,
  callback: IdempotentRequest::RailsCallback,
  storage: IdempotentRequest::RedisStorage.new(::Redis.current, expire_time: 1.day, namespace: 'idempotency_keys')
```

### Policy

Custom class to decide whether the request should be idempotent.

See *Example of integration for rails*

### Storage

Where the response will be stored. Can be any class that implements the following interface:

```ruby
def read(key)
  # read from a storage
end

def write(key, payload)
  # write to a storage
end
```

### Callback

Get notified when the client sends a request with the same idempotency key:

```ruby
class RailsCallback
  attr_reader :request
  
  def initialize(request)
    @request = request
  end
  
  def detected(key:)
    Rails.logger.warn "IdempotentRequest request detected, key: #{key}"
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/idempotent-request. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Idempotent::Request project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/idempotent-request/blob/master/CODE_OF_CONDUCT.md).
