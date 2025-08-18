# frozen_string_literal: true

RSpec::Matchers.define(:be_left) do
  match do |actual|
    @expected_error_class ||= anything
    actual.left? && match(@expected_error_class).matches?(actual.error)
  end

  failure_message do |actual|
    errors = @expected_error_class == anything ? 'any error' : @expected_error_class.name
    "expected #{actual.inspect} to be Left with #{errors}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual.inspect} not to be Left"
  end

  chain(:with) do |expected_error_class|
    @expected_error_class = expected_error_class
  end
end

RSpec::Matchers.define(:be_right) do |expected_value|
  match do |actual|
    expected_value ||= anything
    actual.right_or_raise!
    match(expected_value).matches?(actual.value)
  end

  failure_message do |actual|
    description = expected_value.respond_to?(:description) ? expected_value.description : expected_value.inspect
    "expected #{actual.inspect} to be Right with #{description}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual.inspect} not to be Right"
  end

  chain(:with) do |new_expected_value|
    expected_value = new_expected_value
  end
end
