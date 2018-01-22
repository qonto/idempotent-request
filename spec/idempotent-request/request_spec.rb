require 'spec_helper'

RSpec.describe IdempotentRequest::Request do
  let(:url) { 'https://qonto.eu' }
  let(:default_env) { env_for(url) }
  let(:env) { default_env }
  let(:request) { described_class.new(env) }

  describe '#key' do
    context 'when is default' do
      subject { request.key }

      context 'value is set' do
        let(:env) do
          default_env.merge!(
            'HTTP_IDEMPOTENCY_KEY' => 'test-key'
          )
        end

        it 'should be present' do
          is_expected.to eq('test-key')
        end
      end

      context 'value is not set' do
        it 'should be nil' do
          is_expected.to be_nil
        end
      end
    end

    context 'when is custom' do
      let(:request) { described_class.new(env, header_key: 'X-Qonto-Idempotency-Key') }

      subject { request.key }

      context 'value is set' do
        let(:env) do
          default_env.merge!(
            'HTTP_X_QONTO_IDEMPOTENCY_KEY' => 'custom-key'
          )
        end

        it 'should be present' do
          is_expected.to eq('custom-key')
        end
      end

      context 'value is not set' do
        it 'should be nil' do
          is_expected.to be_nil
        end
      end
    end
  end

  describe '#method_missing' do
    it 'should forward to request' do
      expect(request.request_method).to eq('GET')
    end
  end
end
