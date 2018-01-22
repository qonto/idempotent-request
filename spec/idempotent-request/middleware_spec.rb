require 'spec_helper'

RSpec.describe IdempotentRequest::Middleware do
  let(:app) { -> (env) { [200, {}, 'body'] } }
  let(:env) do
    env_for('https://qonto.eu', method: 'POST')
      .merge!(
        'HTTP_X_QONTO_IDEMPOTENCY_KEY' => 'dont-repeat-this-request-pls'
      )
  end
  let(:storage) { @memory_storage ||= IdempotentRequest::MemoryStorage.new }
  let(:policy) do
    class_double('IdempotentRequest::policy', new: double(should?: true))
  end

  let(:middleware) do
    described_class.new(app,
      policy: policy,
      storage: storage,
      header_key: 'X-Qonto-Idempotency-Key'
    )
  end

  context 'when should be idempotent' do
    it 'should be saved to storage' do
      expect_any_instance_of(IdempotentRequest::RequestManager).to receive(:read)
      expect_any_instance_of(IdempotentRequest::RequestManager).to receive(:write)

      middleware.call(env)
    end

    context 'when has data in storage' do
      before do
        data = [200, {}, 'body']
        allow_any_instance_of(IdempotentRequest::RequestManager).to receive(:read).and_return(data)
      end

      it 'should read from storage' do
        expect_any_instance_of(IdempotentRequest::RequestManager).to receive(:read)
        expect_any_instance_of(IdempotentRequest::RequestManager).not_to receive(:write)

        middleware.call(env)
      end
    end
  end

  context 'when should not be idempotent' do
    let(:policy) do
      class_double('IdempotentRequest::policy', new: double(should?: false))
    end

    it 'should not read storage' do
      expect_any_instance_of(IdempotentRequest::RequestManager).not_to receive(:read)
      expect_any_instance_of(IdempotentRequest::RequestManager).not_to receive(:write)

      middleware.call(env)
    end
  end
end
