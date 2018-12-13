require "bundler/setup"
require 'fakeredis'
require 'byebug'
require "idempotent-request"

spec = File.expand_path('../', __FILE__)
Dir[File.join(spec, 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.include IdempotentRequest::Helpers
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
