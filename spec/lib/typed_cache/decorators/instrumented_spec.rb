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
        result = store.write('key', 'value')
        expect(result.right?).to(be(true))
      end
    end

    describe 'notifications' do
      it 'emits an ActiveSupport event' do
        events = []
        callback = ->(*payload) { events << payload }
        ActiveSupport::Notifications.subscribed(callback, 'typed_cache.write') do
          store.write('key', 'value')
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
          ActiveSupport::Notifications.subscribed(callback, 'typed_cache.write') do
            store.write('key', 'value')
          end
          expect(events).to(be_empty)
        end

        it 'allows subscribing but does not fire for the subscriber' do
          event_fired = false
          store.instrumenter.subscribe('write') do |_|
            event_fired = true
          end
          store.write('key', 'value')
          expect(event_fired).to(be(false))
        end
      end

      describe '#fetch_all' do
        it 'emits a single event for the whole operation' do
          events = []
          callback = ->(*payload) { events << payload }

          ActiveSupport::Notifications.subscribed(callback, 'typed_cache.fetch_all') do
            store.fetch_all(['k1', 'k2']) { |k| "v_#{k}" }
          end

          expect(events.size).to(eq(1))
        end

        it 'does not emit events for the nested fetch calls' do
          events = []
          callback = ->(*payload) { events << payload }

          ActiveSupport::Notifications.subscribed(callback, 'typed_cache.fetch') do
            store.fetch_all(['k1', 'k2']) { |k| "v_#{k}" }
          end

          expect(events).to(be_empty)
        end
      end
    end
  end
end
