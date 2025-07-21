# frozen_string_literal: true

require 'bundler/setup'
require 'reek/rake/task'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

Reek::Rake::Task.new { |task| task.reek_opts = '--config .reek.yml --failure-exit-code 0 --format github' }
RSpec::Core::RakeTask.new { |task| task.verbose = false }
RuboCop::RakeTask.new { |task| task.options = ['--config', '.config/rubocop/config.yml'] }

desc 'Run code quality checks'
task quality: [:reek, :rubocop]

task default: [:quality, :spec]
