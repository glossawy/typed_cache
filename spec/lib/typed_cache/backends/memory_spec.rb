# frozen_string_literal: true

require 'spec_helper'
require 'timecop'

module TypedCache
  module Backends
    RSpec.describe(Memory) do
      include Namespacing

      let(:namespace) { make_namespace('backend_memory') }
      let(:store) { Store.new(namespace, described_class.new) }

      describe '#read' do
        it 'returns Nothing on cache miss' do
          expect(store.read('k')).to(be_cached_value(nothing))
        end
      end

      describe '#write' do
        it 'stores value and returns Right snapshot' do
          result = store.write('k', 'v')
          expect(result).to(be_right)
        end
      end

      describe 'round-trip' do
        it 'gets the previously set value' do
          store.write('k', 'v')
          expect(store.read('k')).to(be_cached_value(some('v')))
        end
      end

      describe '#delete' do
        it 'removes key and returns snapshot' do
          store.write('k', 'v')
          expect(store.delete('k')).to(be_right)
        end
      end

      describe '#clear' do
        it 'empties the namespace' do
          store.write('k', 'v')
          store.clear
          expect(store.key?('k')).to(be(false))
        end
      end

      context 'with TTL configured' do
        let(:store) { Store.new(namespace, described_class.new(ttl: 10)) }

        around do |example|
          Timecop.freeze('2024-01-01 12:00:00 UTC') do
            example.run
          end
        end

        it 'returns a cached value before the TTL' do
          store.write('k', 'v')
          expect(store.read('k')).to(be_cached_value(some('v')))
        end

        it 'returns a cache miss after the TTL' do
          store.write('k', 'v')
          Timecop.travel('2024-01-01 12:00:11 UTC')
          expect(store.read('k')).to(be_cached_value(nothing))
        end

        it 'returns true for key? before expiry' do
          store.write('k', 'v')
          expect(store.key?('k')).to(be(true))
        end

        it 'returns false for key? after expiry' do
          store.write('k', 'v')
          Timecop.travel('2024-01-01 12:00:11 UTC')
          expect(store.key?('k')).to(be(false))
        end

        it 'removes an expired key from the backing store on get' do
          store.write('k', 'v')
          Timecop.travel('2024-01-01 12:00:11 UTC')
          store.read('k') # Trigger the passive eviction
          expect(store.key?('k')).to(be(false))
        end
      end

      describe '#fetch_all' do
        it 'fetches multiple keys, computing if necessary' do
          store.write('key1', 'cached1')

          results = store.fetch_all(['key1', 'key2']) do |key|
            "computed_#{key.key.last}"
          end.right_or_raise!.values

          expect(results).to(
            contain_exactly(
              snapshot_of('cached1'),
              snapshot_of('computed_2'),
            ),
          )
        end
      end

      context 'with default TTL' do
        let(:store) { Store.new(namespace, described_class.new) }

        around do |example|
          Timecop.freeze('2024-01-01 12:00:00 UTC') do
            example.run
          end
        end

        it 'returns a cached value before the default TTL' do
          store.write('k', 'v')
          expect(store.read('k')).to(be_cached_value(some('v')))
        end

        it 'returns a cache miss after the default TTL' do
          store.write('k', 'v')
          Timecop.travel('2024-01-01 12:10:01 UTC') # 601 seconds later
          expect(store.read('k')).to(be_cached_value(nothing))
        end
      end
    end
  end
end
