require 'spec_helper'

RSpec.describe IdempotentRequest::RedisStorage do
  let(:redis) { FakeRedis::Redis.new }
  let(:expire_time) { 3600 }
  let(:redis_storage) { described_class.new(redis, expire_time: expire_time) }

  describe '#read' do
    it 'should be called' do
      expect(redis).to receive(:get)
      expect(redis_storage.read('key')).to be_nil
    end
  end

  describe '#write' do
    let(:key) { 'key' }
    let(:payload) { {} }

    context 'when expire time is not set' do
      let(:redis_storage) { described_class.new(redis) }

      it 'should not set expiration' do
        expect(redis).to receive(:setnx)
        expect(redis).not_to receive(:expire)
        redis_storage.write(key, payload)
      end
    end

    context 'when expire time is set' do
      it 'should set expiration' do
        expect(redis).to receive(:setnx)
        expect(redis).to receive(:expire).with(String, expire_time)
        redis_storage.write(key, payload)
      end
    end
  end

  describe '#namespaced_key' do
    subject { redis_storage.send(:namespaced_key, key) }

    context 'when key contains a space' do
      let(:key) { ' REQUEST-1 ' }

      it 'should be stripped' do
        is_expected.to eq('idempotency_keys:request-1')
      end
    end

    context 'when namespace is not set' do
      let(:key) { 'REQUEST-1' }

      it 'should return with default' do
        is_expected.to eq('idempotency_keys:request-1')
      end
    end

    context 'when namespace is set to nil' do
      let(:redis_storage) { described_class.new(redis, namespace: nil) }
      let(:key) { 'REQUEST-1' }

      it 'should return with default' do
        is_expected.to eq('request-1')
      end
    end
  end
end
