# frozen_string_literal: true

require 'spec_helper'
require 'active_support/notifications'

RSpec.describe('TypedCache integration smoke test') do
  include Namespacing

  let(:namespace) { make_namespace('integration_smoke') }
  let(:events) { [] }
  let(:store) do
    TypedCache.builder
      .with_backend(:memory)
      .with_instrumentation
      .build(namespace).value
  end

  before do
    TypedCache.configure do |config|
      config.instrumentation.enabled = true
    end
    ActiveSupport::Notifications.subscribe(/\.typed_cache\z/) do |*payload|
      events << payload
    end
  end

  after do
    TypedCache.reset_config
    ActiveSupport::Notifications.unsubscribe(/\.typed_cache\z/)
  end

  it 'correctly fetches a computed value and then a cached value' do
    ref = store.ref('greet')
    fresh = ref.fetch { 'hello' }.value
    cached = ref.fetch { 'fail' }.value

    expect(fresh.computed?).to(be(true))
    expect(cached.from_cache?).to(be(true))
  end

  it 'emits instrumentation events for the cache operations' do
    store.ref('greet').fetch { 'hello' }
    store.ref('greet').fetch { 'fail' }

    expect(events).not_to(be_empty)
    expect(events.size).to(eq(2))
  end
end
