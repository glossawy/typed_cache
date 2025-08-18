# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(CacheRef) do
    include Namespacing

    let(:namespace) { make_namespace('cache_ref_spec') }
    let(:store) { create_store(namespace) }

    subject(:ref) { store.ref('test_key') }

    describe '#read' do
      it 'retrieves a cached value' do
        store.write('test_key', 'cached')
        expect(ref.read).to(be_cached_value(some('cached')))
      end

      it 'returns a cache miss error if key not found' do
        expect(ref.read).to(be_cached_value(nothing))
      end
    end

    describe '#write' do
      it 'stores a value in the underlying store' do
        ref.write('new_value')
        expect(store.read('test_key')).to(be_cached_value(some('new_value')))
      end

      it 'returns a snapshot of the set value' do
        result = ref.write('new_value')
        expect(result).to(be_cached_value('new_value'))
      end
    end

    describe '#delete' do
      before { store.write('test_key', 'to_be_deleted') }

      it 'removes a value from the store' do
        ref.delete
        expect(store.key?('test_key')).to(be(false))
      end

      it 'returns the deleted value' do
        result = ref.delete
        expect(result).to(be_right.with(some('to_be_deleted')))
      end
    end

    describe '#fetch' do
      context 'when value is not present' do
        it 'returns a snapshot of the computed value' do
          result = ref.fetch { 'computed' }
          expect(result).to(be_cached_value(some('computed')))
        end

        it 'stores the value in the cache' do
          ref.fetch { 'computed' }
          expect(store.read('test_key')).to(be_cached_value(some('computed')))
        end
      end

      context 'when value is present' do
        before { store.write('test_key', 'cached') }

        it 'returns a snapshot of the cached value' do
          result = ref.fetch { 'fail' }
          expect(result).to(be_cached_value(some('cached')))
        end

        it 'marks the snapshot source as cache' do
          result = ref.fetch { 'fail' }.right_or_raise!
          expect(result.source).to(eq(:cache))
        end

        it 'does not call the block' do
          expect { |b| ref.fetch(&b) }.not_to(yield_control)
        end
      end
    end

    describe '#map' do
      it 'transforms the cached value' do
        store.write('test_key', 'value')
        result = ref.map { |v| "#{v}!" }
        expect(result).to(be_cached_value(some('value!')))
      end

      it 'preserves the snapshot source' do
        store.write('test_key', 'value')
        result = ref.map { |v| "#{v}!" }.right_or_raise!
        expect(result.source).to(eq(:cache))
      end
    end

    describe '#update' do
      before { store.write('test_key', 'original') }

      it 'updates the value in place' do
        ref.update { |v| "#{v}_updated" }
        expect(store.read('test_key')).to(be_cached_value(some('original_updated')))
      end

      it 'returns a snapshot of the updated value' do
        result = ref.update { |v| "#{v}_updated" }
        expect(result).to(be_cached_value(some('original_updated')))
      end
    end

    describe '#compute_if_absent' do
      context 'when value is absent' do
        it 'computes and stores the value' do
          ref.compute_if_absent { 'computed' }
          expect(store.read('test_key')).to(be_cached_value(some('computed')))
        end

        it 'returns a snapshot of the computed value' do
          result = ref.compute_if_absent { 'computed' }
          expect(result).to(be_cached_value(some('computed')))
        end
      end

      context 'when value is present' do
        before { store.write('test_key', 'present') }

        it 'does not compute a new value' do
          ref.compute_if_absent { 'fail' }
          expect(store.read('test_key')).to(be_cached_value(some('present')))
        end

        it 'returns a snapshot of the existing value' do
          result = ref.compute_if_absent { 'fail' }
          expect(result).to(be_cached_value(some('present')))
        end
      end
    end
  end
end
