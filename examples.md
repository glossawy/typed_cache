# TypedCache Examples

This document provides practical examples of using TypedCache in real applications.

## Basic Memory Cache

The simplest way to create a type-safe cache:

```ruby
# The builder can be pre-configured and reused
builder = TypedCache.builder
  .with_backend(:memory, shared: true)
  .with_instrumentation(:rails)

# The store is built with a namespace
users_store = builder.build(TypedCache::Namespace.at("users")).value

# Get a reference to a key
user_ref = users_store.ref("123")

# Set a value
user_ref.set({ id: 123, name: "Jane" })
```

## Rails Integration

Using TypedCache with `Rails.cache` and ActiveSupport notifications:

```ruby
# Use Rails.cache as the backend
builder = TypedCache.builder
  .with_backend(:active_support, Rails.cache)
  .with_instrumentation(:rails)

# Build a store for a specific part of your app
header_store = builder.build(TypedCache::Namespace.at("views:header")).value

# Use a ref to fetch/render
header_ref = header_store.ref("main")
header_html = header_ref.fetch { render_header }.value.value
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

users_store    = base_builder.build(TypedCache::Namespace.at("users")).value
posts_store    = base_builder.build(TypedCache::Namespace.at("posts")).value
comments_store = base_builder.build(TypedCache::Namespace.at("comments")).value
```

## CacheRef API

The `CacheRef` is the most powerful way to interact with a cache key.

```ruby
ref = store.ref("some-key") # => CacheRef
```

### Get a value

The `get` method returns an `Either[Error, Snapshot]`.

```ruby
result = ref.get
result.fold(
  ->(error)    { puts "Cache miss or error: #{error.message}" },
  ->(snapshot) { puts "Found: #{snapshot.value} (from cache: #{snapshot.from_cache?})" }
)
```

### Fetch (get or compute)

The `fetch` method is the most common operation. It gets a value from the cache, but if it's missing, it runs the block, stores the result, and returns it.

```ruby
user = ref.fetch { expensive_user_lookup(123) }.value.value
```

### Mapping values

You can transform the value inside the cache reference without breaking the monadic chain.

```ruby
# user_ref holds { id: 1, name: "John" }
name_ref = user_ref.map { |user| user[:name] }

name_snapshot = name_ref.get.value # => Snapshot(value: "John", ...)
```

### Chaining operations with `bind`

For more complex logic, you can use `bind` (or `flat_map`) to chain operations that return an `Either`.

```ruby
user_ref.bind do |user|
  if user.active?
    posts_ref.set(user.posts)
  else
    TypedCache::Either.left(StandardError.new("User is not active"))
  end
end
```

### Getting the value or a default

If you just want the value and don't care about the `Snapshot` metadata, you can use `value_or`.

```ruby
user_name = user_ref.map { |u| u[:name] }.value_or("Anonymous")
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

## Custom Instrumenter

You can create and register your own instrumenter to integrate with any monitoring or logging system. An instrumenter needs to implement `instrument` and `subscribe` methods.

Here's an example of a simple logging instrumenter:

```ruby
class LoggingInstrumenter
  include TypedCache::Instrumenter
  include TypedCache::Instrumenters::Mixins::NamespacedSingleton

  def instrument(operation, key, **payload, &block)
    puts "[CACHE] Starting: #{operation} for key #{key}"
    result = block.call
    puts "[CACHE] Finished: #{operation} for key #{key}"
    result
  end

  def subscribe(operation, **_filters, &block)
    # For simplicity, this example doesn't implement a full subscription model,
    # but in a real-world scenario, you would store and manage callbacks here.
    puts "[CACHE] Subscribed to '#{operation}'"
  end
end

# Register the new instrumenter
TypedCache::Instrumenters.register(:logger, LoggingInstrumenter)

# Use it in the builder
logging_cache = TypedCache.builder
  .with_backend(:memory)
  .with_instrumentation(:logger)
  .build.value

# Subscribe to an event
logging_cache.instrumenter.subscribe("get")

# Operations will now be logged
logging_cache.ref("test").set("hello")
# => [CACHE] Starting: set for key test
# => [CACHE] Finished: set for key test
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
