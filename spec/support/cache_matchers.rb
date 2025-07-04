# frozen_string_literal: true

RSpec::Matchers.define(:be_snapshot) do |expected_value|
  match do |actual|
    an_instance_of(TypedCache::Snapshot).and(have_attributes(
      value: expected_value,
    )).matches?(actual)
  end

  failure_message do |actual|
    "expected #{actual} to be a snapshot with value #{expected_value}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual} to not be a snapshot with value #{expected_value}"
  end

  description do
    "be a snapshot with value #{expected_value}"
  end
end

RSpec::Matchers.alias_matcher(:snapshot_of, :be_snapshot)

RSpec::Matchers.define(:be_cached_value) do |expected_value|
  match do |actual|
    be_right.with(snapshot_of(expected_value)).matches?(actual)
  end

  failure_message do |actual|
    "expected #{actual} to be a cache result with value #{expected_value}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual} to not be a cache result with value #{expected_value}"
  end

  description do
    "be a cache result with value #{expected_value}"
  end
end

RSpec::Matchers.alias_matcher(:cached_value_of, :be_cached_value)

RSpec::Matchers.define(:be_cache_key) do |expected_key|
  match do |actual|
    an_instance_of(TypedCache::CacheKey).and(have_attributes(
      key: expected_key,
    )).matches?(actual)
  end

  failure_message do |actual|
    "expected #{actual} to be a cache key with value #{expected_key}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual} to not be a cache key with value #{expected_key}"
  end

  description do
    "be a cache key with value #{expected_key}"
  end
end

RSpec::Matchers.alias_matcher(:a_cache_key, :be_cache_key)

RSpec::Matchers.define(:be_cache_reference) do |expected_key|
  match do |actual|
    an_instance_of(TypedCache::CacheRef).and(have_attributes(
      key: a_cache_key(expected_key),
    )).matches?(actual)
  end

  failure_message do |actual|
    "expected #{actual} to be a cache reference with key #{expected_key}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual} to not be a cache reference with key #{expected_key}"
  end

  description do
    "be a cache reference with value #{expected_key}"
  end
end

RSpec::Matchers.alias_matcher(:a_cache_reference, :be_cache_reference)
