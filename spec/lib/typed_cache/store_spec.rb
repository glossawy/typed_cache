# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(Store) do
    include Namespacing

    let(:store_class) do
      Class.new do
        include Store
        attr_accessor :namespace

        def initialize(namespace)
          @namespace = namespace
          @data = {}
        end

        def get(key)
          namespaced_key = namespaced_key(key)
          if @data.key?(namespaced_key)
            Either.right(Snapshot.cached(namespaced_key, @data[namespaced_key]))
          else
            Either.left(CacheMissError.new(namespaced_key))
          end
        end

        def set(key, value)
          namespaced_key = namespaced_key(key)
          @data[namespaced_key] = value
          Either.right(Snapshot.cached(namespaced_key, value))
        end
      end
    end

    let(:namespace) { make_namespace('store_spec') }
    let(:store) { store_class.new(namespace) }

    describe '#fetch' do
      context 'when value is not present' do
        it 'computes the value' do
          result = store.fetch('my_key') { 'computed' }
          expect(result).to(be_right.with(snapshot_of('computed')))
        end

        it 'sets the computed value in the store' do
          store.fetch('my_key') { 'computed' }
          expect(store.get('my_key')).to(be_right.with(snapshot_of('computed')))
        end
      end

      context 'when value is present' do
        before { store.set('my_key', 'cached') }

        it 'returns the cached value' do
          result = store.fetch('my_key') { 'fail' }
          expect(result).to(be_right.with(snapshot_of('cached')))
        end

        it 'does not call the block' do
          expect { |b| store.fetch('my_key', &b) }.not_to(yield_control)
        end
      end
    end

    describe '#fetch_all' do
      it 'fetches multiple keys, computing if necessary' do
        store.set('key1', 'cached1')
        results = store.fetch_all(['key1', 'key2']) do |key|
          "computed_#{key.key.last}"
        end.value

        expect(results.map(&:value)).to(contain_exactly('cached1', 'computed_2'))
      end

      it 'returns snapshots with correct sources' do
        store.set('key1', 'cached1')
        results = store.fetch_all(['key1', 'key2']) do |key|
          "computed_#{key.key.last}"
        end.value

        cached_snapshot = results.find { |s| s.value == 'cached1' }
        computed_snapshot = results.find { |s| s.value == 'computed_2' }

        expect([cached_snapshot.source, computed_snapshot.source]).to(eq([:cache, :computed]))
      end
    end

    describe '#with_namespace' do
      context 'with a string' do
        it 'returns a new store with a nested namespace' do
          new_store = store.with_namespace('nested')
          expect(new_store.namespace.to_s).to(eq("#{namespace}:nested"))
        end
      end

      context 'with a Namespace object' do
        it 'returns a new store with that namespace' do
          other_namespace = make_namespace('other')
          new_store = store.with_namespace(other_namespace)
          expect(new_store.namespace).to(eq(other_namespace))
        end
      end

      context 'with an array of strings' do
        it 'returns a new store with a nested namespace' do
          new_store = store.with_namespace(['nested', 'other'])
          expect(new_store.namespace.to_s).to(eq("#{namespace}:nested:other"))
        end
      end

      it 'does not modify the original store' do
        store.with_namespace('nested')
        expect(store.namespace).to(eq(namespace))
      end
    end

    describe '#ref' do
      it 'returns a CacheRef for the given key' do
        ref = store.ref('my_key')
        expect(ref).to(be_cache_reference('my_key'))
      end

      it 'the returned ref uses the correct store' do
        ref = store.ref('my_key')
        expect(ref.store).to(be(store))
      end
    end
  end
end
