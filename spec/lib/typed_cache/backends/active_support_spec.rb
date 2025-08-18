# frozen_string_literal: true

require 'spec_helper'
require 'active_support/cache'

module TypedCache
  module Backends
    RSpec.describe(ActiveSupport) do
      include Namespacing

      let(:namespace) { make_namespace('backend_as') }
      let(:cache_store) { ::ActiveSupport::Cache::MemoryStore.new }
      let(:store) { Store.new(namespace, described_class.new(cache_store)) }

      describe '#write / #read' do
        it 'round-trips a value' do
          store.write('k', 'v')
          expect(store.read('k')).to(be_cached_value(some('v')))
        end
      end

      describe '#key?' do
        it 'reflects existence' do
          store.write('k', 1)
          expect(store.key?('k')).to(be(true))
        end
      end

      describe '#fetch_all' do
        it 'fetches multiple keys, computing if necessary' do
          store.write('key1', 'cached1')

          results = store.fetch_all(['key1', 'key2']) do |key|
            "computed_#{key}"
          end.right_or_raise!.values
          expect(results).to(
            contain_exactly(
              snapshot_of('cached1'),
              snapshot_of('computed_typed_cache:backend_as:key2'),
            ),
          )
        end
      end

      describe '#clear' do
        it 'removes keys via delete_matched' do
          store.write('k', 1)
          store.clear
          expect(store.key?('k')).to(be(false))
        end
      end
    end
  end
end
