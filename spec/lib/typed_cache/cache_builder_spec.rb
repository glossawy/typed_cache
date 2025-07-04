# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(CacheBuilder) do
    include Namespacing

    let(:namespace) { make_namespace('builder_spec') }

    describe 'happy path' do
      it 'builds a memory store successfully' do
        builder = TypedCache.builder.with_backend(:memory)
        result = builder.build(namespace)
        expect(result).to(be_right.with(an_instance_of(Backends::Memory)))
      end

      it 'passes arguments to the backend constructor' do
        builder = TypedCache.builder.with_backend(:memory, shared: true)
        result = builder.build(namespace)
        expect(result).to(be_right)
      end
    end

    context 'when backend is missing' do
      it 'returns Left with ArgumentError' do
        builder = TypedCache.builder # no backend configured
        result = builder.build(namespace)
        expect(result.left?).to(be(true))
      end
    end

    describe 'decorator chain' do
      before do
        dummy_deco = Class.new do
          include Decorator
          def initialize(store) = @store = store
          def get(key) = @store.get(key).map { |snap| snap.map { "decorated_#{_1}" } }
          def set(key, value) = @store.set(key, value)
          def method_missing(m, *a, &b) = @store.public_send(m, *a, &b)
          def respond_to_missing?(m, inc = false) = @store.respond_to?(m, inc)
          attr_reader :store
        end.set_temporary_name('dummy_deco')
        Decorators.register(:dummy, dummy_deco)
      end

      it 'applies decorators in order' do
        builder = TypedCache.builder
          .with_backend(:memory)
          .with_decorator(:dummy)
        store = builder.build(namespace).value
        store.set('k', 'v')
        result = store.get('k')
        expect(result).to(be_cached_value('decorated_v'))
      end
    end
  end
end
