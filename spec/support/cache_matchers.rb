# frozen_string_literal: true

RSpec::Matchers.define(:be_snapshot) do |expected_value|
  match do |actual|
    an_instance_of(TypedCache::Snapshot).and(have_attributes(
      value: expected_value,
    )).matches?(actual)
  end

  failure_message do |actual|
    description = expected_value.respond_to?(:description) ? expected_value.description : expected_value.inspect
    "expected #{actual.inspect} to be a snapshot with value #{description}"
  end

  failure_message_when_negated do |actual|
    description = expected_value.respond_to?(:description) ? expected_value.description : expected_value.inspect
    "expected #{actual.inspect} to not be a snapshot with value #{description}"
  end

  description do
    description = expected_value.respond_to?(:description) ? expected_value.description : expected_value.inspect
    "be a snapshot with value #{description}"
  end
end

RSpec::Matchers.alias_matcher(:snapshot_of, :be_snapshot)

RSpec::Matchers.define(:be_cached_value) do |expected_value|
  match do |actual|
    be_right.with(snapshot_of(expected_value)).matches?(actual)
  end

  failure_message do |actual|
    description = expected_value.respond_to?(:description) ? expected_value.description : expected_value.inspect
    "expected #{actual.inspect} to be a cache result with value #{description}"
  end

  failure_message_when_negated do |actual|
    description = expected_value.respond_to?(:description) ? expected_value.description : expected_value.inspect
    "expected #{actual.inspect} to not be a cache result with value #{description}"
  end

  description do
    description = expected_value.respond_to?(:description) ? expected_value.description : expected_value.inspect
    "be a cache result with value #{description}"
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
    description = expected_key.respond_to?(:description) ? expected_key.description : expected_key.inspect
    "expected #{actual} to be a cache key with value #{description}"
  end

  failure_message_when_negated do |actual|
    description = expected_key.respond_to?(:description) ? expected_key.description : expected_key.inspect
    "expected #{actual} to not be a cache key with value #{description}"
  end

  description do
    description = expected_key.respond_to?(:description) ? expected_key.description : expected_key.inspect
    "be a cache key with value #{description}"
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
    description = expected_key.respond_to?(:description) ? expected_key.description : expected_key.inspect
    "expected #{actual} to be a cache reference with key #{description}"
  end

  failure_message_when_negated do |actual|
    description = expected_key.respond_to?(:description) ? expected_key.description : expected_key.inspect
    "expected #{actual} to not be a cache reference with key #{description}"
  end

  description do
    description = expected_key.respond_to?(:description) ? expected_key.description : expected_key.inspect
    "be a cache reference with value #{description}"
  end
end

RSpec::Matchers.alias_matcher(:a_cache_reference, :be_cache_reference)
