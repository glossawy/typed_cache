# TypedCache Examples

This document provides practical examples of using TypedCache in real applications.

## Basic Memory Cache

The simplest way to create a type-safe cache:

```ruby
user_namespace = TypedCache::Namespace.at("users")

cache_result = TypedCache.builder
  .with_backend(:memory, shared: true)
  .with_instrumentation
  .build(user_namespace)            # => Either[Error, Store]

store = cache_result.value          # unwrap for brevity
key   = store.namespace.key("123")  # => CacheKey
store.set(key, { id: 123, name: "Jane" })
```

## Rails Integration

Using TypedCache with `Rails.cache` and ActiveSupport notifications:

```ruby
cache_result = TypedCache.builder
  .with_backend(:active_support, Rails.cache)
  .with_instrumentation
  .build                                     # defaults to TypedCache.config.default_namespace

cache = cache_result.value
cache.fetch(cache.namespace.key("header")) { render_header }
```

## Pattern Matching

Clean error handling with Ruby 3 pattern matching:

```ruby
result = TypedCache.builder
  .with_backend(:memory)
  .build

case result
in TypedCache::Either::Right(store)
  store.set(store.namespace.key("greeting"), "Hello")
in TypedCache::Either::Left(error)
  warn "Failed to set up cache: #{error.message}"
end
```

## Multiple Caches

Reuse a preconfigured builder for several namespaces:

```ruby
base_builder = TypedCache.builder
  .with_backend(:memory, shared: true)

users_store  = base_builder.build(TypedCache::Namespace.at("users")).value
posts_store  = base_builder.build(TypedCache::Namespace.at("posts")).value
comments_store = base_builder.build(TypedCache::Namespace.at("comments")).value
```

## Cache Operations

Working with cache values using the monadic interface:

```ruby
# Set a value
cache.set({ id: 1, name: "John" })

# Get with error handling
cache.get.fold(
  ->(error) { puts "Cache miss: #{error.message}" },
  ->(snapshot) { puts "Found: #{snapshot.value}" }
)

# Get with Maybe semantics (no error details)
user = cache.peek.value_or({ id: 0, name: "Anonymous" })

# Fetch with computation
result = cache.fetch do
  # This block runs only on cache miss
  expensive_user_lookup(user_id)
end
```

## Custom Backend

Registering and using a custom cache backend:

```ruby
class SimpleStore
  include TypedCache::Backend

  def initialize(namespace)
    @namespace = namespace
    @data      = {}
  end

  def get(key)
    value = @data[key]
    value ? TypedCache::Either.right(value) : TypedCache::Either.left(TypedCache::CacheMissError.new(key))
  end

  def set(key, value)
    @data[key] = value
    TypedCache::Either.right(value)
  end

  def delete(key)
    value = @data.delete(key)
    value ? TypedCache::Either.right(value) : TypedCache::Either.left(TypedCache::CacheMissError.new(key))
  end

  attr_reader :namespace
  def store_type = "simple"
end

TypedCache::Backends.register(:simple, SimpleStore)

cache = TypedCache.builder
  .with_backend(:simple)
  .build.value
```

## Instrumentation Only

```ruby
TypedCache.configure_instrumentation do |config|
  config.enabled = true
  config.namespace = "my_app_cache"
end

cache = TypedCache.builder
  .with_backend(:memory)
  .with_instrumentation
  .build.value

cache.set(cache.namespace.key("metrics"), 42)
```

## Configuration Snippet

```ruby
TypedCache.configure do |config|
  config.default_namespace = "my_app"
end
```

You can register additional decorators or back-ends as needed:

```ruby
TypedCache::Decorators.register(:logger, MyLoggerDecorator)
TypedCache::Backends.register(:redis,   MyRedisBackend)
```

## Thread Safety

The shared in-memory back-end is thread-safe:

```ruby
shared_store = TypedCache.builder
  .with_backend(:memory, shared: true)
  .build.value

threads = 10.times.map do |i|
  Thread.new { shared_store.set(shared_store.namespace.key(i.to_s), "data_") }
end
threads.each(&:join)
```

## Testing

Using TypedCache in tests:

```ruby
spec_store = TypedCache.builder
  .with_backend(:memory)
  .build(TypedCache::Namespace.at("specs")).value

RSpec.describe "cache" do
  it "stores data" do
    result = spec_store.set(spec_store.namespace.key("id"), 1)
    expect(result).to be_right
  end
end
```
