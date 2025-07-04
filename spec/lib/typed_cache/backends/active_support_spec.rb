# frozen_string_literal: true

require 'spec_helper'
require 'active_support/cache'

module TypedCache
  module Backends
    RSpec.describe(ActiveSupport) do
      include Namespacing

      let(:namespace) { make_namespace('backend_as') }
      let(:cache_store) { ::ActiveSupport::Cache::MemoryStore.new }
      let(:store) { described_class.new(namespace, cache_store) }

      describe '#set / #get' do
        it 'round-trips a value' do
          store.set('k', 'v')
          expect(store.get('k').value.value).to(eq('v'))
        end
      end

      describe '#key?' do
        it 'reflects existence' do
          store.set('k', 1)
          expect(store.key?('k')).to(be(true))
        end
      end

      describe '#clear' do
        it 'removes keys via delete_matched' do
          store.set('k', 1)
          store.clear
          expect(store.key?('k')).to(be(false))
        end
      end
    end
  end
end
