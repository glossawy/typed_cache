# frozen_string_literal: true

RSpec::Matchers.define(:be_left) do
  match do |actual|
    @expected_error_class ||= anything
    actual.left? && match(@expected_error_class).matches?(actual.error)
  end

  failure_message do |actual|
    actual_repr = Object.instance_method(:to_s).bind_call(actual)
    "expected #{actual_repr} to be Left"
  end

  failure_message_when_negated do |actual|
    actual_repr = Object.instance_method(:to_s).bind_call(actual)
    "expected #{actual_repr} not to be Left"
  end

  chain(:with) do |expected_error_class|
    @expected_error_class = expected_error_class
  end
end

RSpec::Matchers.define(:be_right) do
  match do |actual|
    @expected_value ||= anything
    actual.right? && match(@expected_value).matches?(actual.value)
  end

  failure_message do |actual|
    actual_repr = Object.instance_method(:to_s).bind_call(actual)
    "expected #{actual_repr} to be Right"
  end

  failure_message_when_negated do |actual|
    actual_repr = Object.instance_method(:to_s).bind_call(actual)
    "expected #{actual_repr} not to be Right"
  end

  chain(:with) do |expected_value|
    @expected_value = expected_value
  end
end
