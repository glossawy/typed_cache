# frozen_string_literal: true

require 'spec_helper'
require 'active_support/notifications'

module TypedCache
  RSpec.describe(Decorators::Instrumented) do
    include Namespacing

    let(:namespace) { make_namespace('instrumented_spec') }
    let(:builder) do
      TypedCache.builder
        .with_backend(:memory)
        .with_instrumentation(:rails)
    end
    let(:store) { builder.build(namespace).value }

    before do
      TypedCache.configure do |config|
        config.instrumentation.enabled = true
        config.instrumentation.namespace = 'typed_cache'
      end
    end

    after { TypedCache.reset_config }

    describe 'delegation' do
      it 'returns the underlying store result' do
        result = store.set('key', 'value')
        expect(result.right?).to(be(true))
      end
    end

    describe 'notifications' do
      it 'emits an ActiveSupport event' do
        events = []
        callback = ->(*payload) { events << payload }
        ActiveSupport::Notifications.subscribed(callback, 'typed_cache.set') do
          store.set('key', 'value')
        end
        expect(events.size).to(eq(1))
      end

      context 'when instrumentation is disabled' do
        before do
          TypedCache.configure do |config|
            config.instrumentation.enabled = false
          end
        end

        it 'does not emit an event' do
          events = []
          callback = ->(*payload) { events << payload }
          ActiveSupport::Notifications.subscribed(callback, 'typed_cache.set') do
            store.set('key', 'value')
          end
          expect(events).to(be_empty)
        end

        it 'allows subscribing but does not fire for the subscriber' do
          event_fired = false
          store.instrumenter.subscribe('set') do |_|
            event_fired = true
          end
          store.set('key', 'value')
          expect(event_fired).to(be(false))
        end
      end
    end
  end
end
