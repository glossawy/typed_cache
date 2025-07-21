# frozen_string_literal: true

require_relative 'lib/typed_cache/version.rb'

Gem::Specification.new do |spec|
  spec.name = 'typed_cache'
  spec.version = TypedCache::VERSION
  spec.authors = ['Autumn Winter']
  spec.email = ['glossawy@sphorb.email']
  spec.homepage = 'https://github.com/glossawy/typed_cache'
  spec.summary = 'A robust, type-safe caching library that provides explicit, predictable cache interactions with rich, context-aware results'
  spec.description = <<~DESCRIPTION
    TypedCache is a Ruby caching library designed to eliminate common caching pitfalls by providing a monadic, type-safe API that makes cache operations explicit and predictable. Cache interactions are first-class operations with
    comprehensive error handling and transparent state management. The library supports wrapping other caching libraries via custom backends and ActiveSupport::Cache is supported out of the box.
  DESCRIPTION
  spec.license = 'Apache-2.0'

  spec.metadata = {
    'issue_tracker_uri' => 'https://github.com/glossawy/typed_cache/issues',
    'changelog_uri' => "https://github.com/glossawy/typed_cache/blob/main/VERSIONS.adoc##{TypedCache::VERSION.delete(".")}",
    'license_uri' => 'https://github.com/glossawy/typed_cache/blob/main/LICENSE',
    'label' => 'caching',
    'labels' => ['typed_cache', 'ruby', 'caching', 'type-safety', 'rails', 'rbs'].join(','),
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/glossawy/typed_cache',
  }

  spec.signing_key = Gem.default_key_path
  spec.cert_chain = [Gem.default_cert_path]

  spec.required_ruby_version = '>= 3.2.0'
  spec.add_dependency('concurrent-ruby', '~> 1.3.5')
  spec.add_dependency('concurrent-ruby-edge', '~>0.7.2')
  spec.add_dependency('dry-configurable', '~> 1.0')
  spec.add_dependency('dry-struct', '~> 1.0')
  spec.add_dependency('dry-types', '~>1.0')
  spec.add_dependency('multi_json', '~> 1.17')
  spec.add_dependency('zeitwerk', '~> 2.7')

  spec.extra_rdoc_files = Dir['README*', 'LICENSE*', 'examples*']
  spec.files = Dir['*.gemspec', 'lib/**/*', 'sig/**/*']
end
