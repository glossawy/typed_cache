# frozen_string_literal: true

require 'spec_helper'
require 'timecop'

module TypedCache
  module Backends
    RSpec.describe(Memory) do
      include Namespacing

      let(:namespace) { make_namespace('backend_memory') }
      let(:store) { described_class.new(namespace) }

      describe '#get' do
        it 'returns Left on cache miss' do
          expect(store.get('k').left?).to(be(true))
        end
      end

      describe '#set' do
        it 'stores value and returns Right snapshot' do
          result = store.set('k', 'v')
          expect(result.right?).to(be(true))
        end
      end

      describe 'round-trip' do
        it 'gets the previously set value' do
          store.set('k', 'v')
          expect(store.get('k').value.value).to(eq('v'))
        end
      end

      describe '#delete' do
        it 'removes key and returns snapshot' do
          store.set('k', 'v')
          expect(store.delete('k').right?).to(be(true))
        end
      end

      describe '#clear' do
        it 'empties the namespace' do
          store.set('k', 'v')
          store.clear
          expect(store.key?('k')).to(be(false))
        end
      end

      context 'with TTL configured' do
        let(:store) { described_class.new(namespace, ttl: 10) }

        around do |example|
          Timecop.freeze('2024-01-01 12:00:00 UTC') do
            example.run
          end
        end

        it 'returns a cached value before the TTL' do
          store.set('k', 'v')
          expect(store.get('k')).to(be_cached_value('v'))
        end

        it 'returns a cache miss after the TTL' do
          store.set('k', 'v')
          Timecop.travel('2024-01-01 12:00:11 UTC')
          expect(store.get('k')).to(be_left.with(an_instance_of(CacheMissError)))
        end

        it 'returns true for key? before expiry' do
          store.set('k', 'v')
          expect(store.key?('k')).to(be(true))
        end

        it 'returns false for key? after expiry' do
          store.set('k', 'v')
          Timecop.travel('2024-01-01 12:00:11 UTC')
          expect(store.key?('k')).to(be(false))
        end

        it 'has the correct size before expiry' do
          store.set('k1', 'v1')
          store.set('k2', 'v2')
          expect(store.size).to(eq(2))
        end

        it 'has the correct size after expiry' do
          store.set('k1', 'v1')
          store.set('k2', 'v2')
          Timecop.travel('2024-01-01 12:00:11 UTC')
          expect(store.size).to(eq(0))
        end

        it 'has a key in the backing store before expiry' do
          store.set('k', 'v')
          namespaced_key = store.send(:namespaced_key, 'k')
          expect(store.send(:backing_store)).to(have_key(namespaced_key))
        end

        it 'removes an expired key from the backing store on get' do
          store.set('k', 'v')
          namespaced_key = store.send(:namespaced_key, 'k')
          Timecop.travel('2024-01-01 12:00:11 UTC')
          store.get('k') # Trigger the passive eviction
          expect(store.send(:backing_store)).not_to(have_key(namespaced_key))
        end
      end

      context 'with default TTL' do
        let(:store) { described_class.new(namespace) }

        around do |example|
          Timecop.freeze('2024-01-01 12:00:00 UTC') do
            example.run
          end
        end

        it 'returns a cached value before the default TTL' do
          store.set('k', 'v')
          expect(store.get('k')).to(be_cached_value('v'))
        end

        it 'returns a cache miss after the default TTL' do
          store.set('k', 'v')
          Timecop.travel('2024-01-01 12:10:01 UTC') # 601 seconds later
          expect(store.get('k')).to(be_left.with(an_instance_of(CacheMissError)))
        end
      end
    end
  end
end
