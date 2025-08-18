# frozen_string_literal: true

Bundler.require :tools
Bundler.require :test

require 'dry/configurable/test_interface'
require 'typed_cache'

SPEC_ROOT = Pathname(__dir__).realpath.freeze

Dir[SPEC_ROOT.join('support/shared_contexts/**/*.rb')].sort.each { |f| require f }
Dir[SPEC_ROOT.join('support/shared_examples/**/*.rb')].sort.each { |f| require f }
Dir[SPEC_ROOT.join('support/helpers/**/*.rb')].sort.each { |f| require f }

ObjectSpace.each_object(Dry::Configurable) do |klass|
  klass.module_eval do
    enable_test_interface
  end
end

# Load custom matchers
require_relative 'support/either_matchers'
require_relative 'support/cache_matchers'
require_relative 'support/maybe_matchers'

RSpec.configure do |config|
  config.color = true
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = './tmp/rspec-examples.txt'
  config.filter_run_when_matching(:focus)
  config.formatter = ENV.fetch('CI', false) == 'true' ? :progress : :documentation
  config.order = :random
  config.pending_failure_output = :no_backtrace
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.warnings = true

  config.expect_with(:rspec) do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end

  config.after do
    TypedCache.reset_config
    Timecop.return
    TypedCache::Instrumenters::Mixins::NamespacedSingleton.all.each do |klass|
      klass.namespace_cache.clear
    end
  end
end
