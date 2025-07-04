# frozen_string_literal: true

require 'spec_helper'
require 'active_support/notifications'

RSpec.describe('TypedCache integration smoke test') do
  include Namespacing

  let(:namespace) { make_namespace('integration_smoke') }

  before do
    TypedCache.configure do |config|
      config.instrumentation.enabled = true
    end
  end

  after { TypedCache.reset_config }

  it 'performs full cache cycle with instrumentation' do
    events = []
    ActiveSupport::Notifications.subscribed(->(*payload) { events << payload }, /\.typed_cache\z/) do
      store = TypedCache.builder
        .with_backend(:memory)
        .with_instrumentation
        .build(namespace).value

      ref = store.ref('greet')
      fresh = ref.fetch { 'hello' }.value
      cached = ref.fetch { 'fail' }.value

      expect(fresh.computed?).to(be(true))
      expect(cached.from_cache?).to(be(true))
    end

    expect(events).not_to(be_empty)
  end
end
