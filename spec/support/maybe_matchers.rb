# frozen_string_literal: true

RSpec::Matchers.define(:nothing) do
  match do |actual|
    actual.is_a?(TypedCache::Nothing)
  end

  failure_message do |actual|
    "expected #{actual} to be Nothing, but was #{actual.inspect}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual} to not be Nothing"
  end

  description do
    'be Nothing'
  end
end

RSpec::Matchers.define(:some) do |expected_value|
  match do |actual|
    actual.is_a?(TypedCache::Some) && match(expected_value).matches?(actual.value)
  end

  failure_message do |actual|
    "expected #{actual} to be Some(#{expected_value.inspect}), but was #{actual.inspect}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual} to not be Some(#{expected_value.inspect})"
  end

  description do
    "be Some(#{expected_value.inspect})"
  end
end
