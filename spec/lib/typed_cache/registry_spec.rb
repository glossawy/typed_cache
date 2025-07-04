# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(Registry) do
    subject(:registry) { described_class.new('widget') }

    describe '#register' do
      it 'adds a class under a key' do
        dummy = Class.new
        registry.register(:dummy, dummy)
        expect(registry.registered?(:dummy)).to(be(true))
      end
    end

    describe '#resolve' do
      it 'instantiates registered class' do
        klass = Class.new { def initialize; end }
        registry.register(:x, klass)
        res = registry.resolve(:x)
        expect(res.value).to(be_a(klass))
      end

      it 'returns Left on unknown key' do
        res = registry.resolve(:none)
        expect(res.left?).to(be(true))
      end
    end
  end
end
