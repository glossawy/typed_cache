# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(Either) do
    describe '.right?' do
      it 'returns true on Right' do
        expect(described_class.right(1).right?).to(be(true))
      end

      it 'returns false on Left' do
        expect(described_class.left(:err).right?).to(be(false))
      end
    end

    describe '.left?' do
      it 'returns true on Left' do
        expect(described_class.left(:err).left?).to(be(true))
      end

      it 'returns false on Right' do
        expect(described_class.right(1).left?).to(be(false))
      end
    end

    describe '#map' do
      it 'maps over Right value' do
        result = described_class.right(2).map { |v| v * 2 }
        expect(result.value).to(eq(4))
      end

      it 'returns same Left unmodified' do
        err = described_class.left('oops')
        expect(err.map { raise }.error).to(eq('oops'))
      end
    end

    describe '#bind' do
      it 'chains Rights' do
        res = described_class.right(1).bind { |v| described_class.right(v + 1) }
        expect(res.value).to(eq(2))
      end

      it 'does not call block on Left' do
        res = described_class.left('err').bind { |v| described_class.right(v) }
        expect(res.error).to(eq('err'))
      end
    end

    describe '#fold' do
      it 'yields Right branch' do
        result = described_class.right(10).fold(->(_) { :left }, ->(v) { v })
        expect(result).to(eq(10))
      end

      it 'yields Left branch' do
        result = described_class.left('x').fold(->(e) { e }, ->(_) { :right })
        expect(result).to(eq('x'))
      end
    end

    describe '#right_or_else' do
      it 'yields Right branch' do
        result = described_class.right(10).right_or_else { |v| v * 2 }
        expect(result).to(eq(10))
      end

      it 'yields Left branch' do
        result = described_class.left('x').right_or_else { |v| v * 2 }
        expect(result).to(eq('xx'))
      end
    end

    describe '#right_or_raise!' do
      it 'returns Right value' do
        result = described_class.right(10).right_or_raise!
        expect(result).to(eq(10))
      end

      it 'raises Left error' do
        expect { described_class.left(RuntimeError.new('x')).right_or_raise! }.to(raise_error('x'))
      end
    end
  end
end
