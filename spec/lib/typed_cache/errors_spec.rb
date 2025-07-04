# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(Error) do
    it 'is a standard error' do
      expect(described_class.new).to(be_a(StandardError))
    end
  end

  RSpec.describe(StoreError) do
    let(:key) { 'my_key' }
    let(:operation) { :get }

    context 'without an original error' do
      subject(:error) { described_class.new(operation, key, 'Something went wrong') }

      it 'has a detailed message' do
        expect(error.detailed_message).to(eq("GET operation failed for key 'my_key': Something went wrong"))
      end

      it 'does not have a cause' do
        expect(error.has_cause?).to(be(false))
      end
    end

    context 'with an original error' do
      let(:original_error) { StandardError.new('underlying issue') }

      subject(:error) { described_class.new(operation, key, 'Something went wrong', original_error) }

      it 'has a detailed message including the cause' do
        expected = "GET operation failed for key 'my_key': Something went wrong (StandardError: underlying issue)"
        expect(error.detailed_message).to(eq(expected))
      end

      it 'has a cause' do
        expect(error.has_cause?).to(be(true))
      end
    end
  end

  RSpec.describe(TypeError) do
    subject(:error) { described_class.new('String', 'Integer', 123, 'Type mismatch') }

    it 'has a custom message' do
      expect(error.message).to(eq('Type mismatch'))
    end

    it 'has a type mismatch message' do
      expect(error.type_mismatch_message).to(eq('Expected String, got Integer'))
    end
  end

  RSpec.describe(CacheMissError) do
    let(:key) { instance_double(CacheKey, to_s: 'ns:my_key') }

    subject(:error) { described_class.new(key) }

    it 'has a standard message' do
      expect(error.message).to(eq('Cache miss for key: ns:my_key'))
    end

    it 'is a cache miss' do
      expect(error.cache_miss?).to(be(true))
    end
  end
end
