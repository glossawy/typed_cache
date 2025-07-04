# frozen_string_literal: true

ruby file: '.ruby-version'

source 'https://rubygems.org'

gemspec

group :development do
  gem 'rake', '~> 13.3'
end

group :test do
  gem 'timecop', '~>0.9.10'
  gem 'rspec', '~> 3.13'
  gem 'activesupport', '~>7.1.0', require: 'active_support/all'
end

group :tools do
  gem 'pry'
  gem 'pry-byebug'

  gem 'rubocop', '~>1.74.0', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-shopify', require: false
  gem 'rubocop-sorbet', '~>0.9.0', require: false
  gem 'rubocop-thread_safety', require: false

  gem 'rbs', require: false
  gem 'rbs-inline', require: false

  gem 'steep', require: false
end
