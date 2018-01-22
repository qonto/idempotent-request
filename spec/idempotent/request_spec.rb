require "spec_helper"

RSpec.describe Idempotent::Request do
  it "has a version number" do
    expect(Idempotent::Request::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
