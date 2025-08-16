# TypedCache

[![Gem Version](https://img.shields.io/gem/v/typed_cache?style=flat-square&logo=rubygems)](https://rubygems.org/gems/typed_cache)
![GitHub Release Date](https://img.shields.io/github/release-date/glossawy/typed_cache?style=flat-square&label=released&logo=semanticrelease)
![GitHub last commit](https://img.shields.io/github/last-commit/glossawy/typed_cache?style=flat-square&logo=git)

![GitHub License](https://img.shields.io/github/license/glossawy/typed_cache?style=flat-square&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NDAgNTEyIj48IS0tIUZvbnQgQXdlc29tZSBGcmVlIDYuNy4yIGJ5IEBmb250YXdlc29tZSAtIGh0dHBzOi8vZm9udGF3ZXNvbWUuY29tIExpY2Vuc2UgLSBodHRwczovL2ZvbnRhd2Vzb21lLmNvbS9saWNlbnNlL2ZyZWUgQ29weXJpZ2h0IDIwMjUgRm9udGljb25zLCBJbmMuLS0%2BPHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTM4NCAzMmwxMjggMGMxNy43IDAgMzIgMTQuMyAzMiAzMnMtMTQuMyAzMi0zMiAzMkwzOTguNCA5NmMtNS4yIDI1LjgtMjIuOSA0Ny4xLTQ2LjQgNTcuM0wzNTIgNDQ4bDE2MCAwYzE3LjcgMCAzMiAxNC4zIDMyIDMycy0xNC4zIDMyLTMyIDMybC0xOTIgMC0xOTIgMGMtMTcuNyAwLTMyLTE0LjMtMzItMzJzMTQuMy0zMiAzMi0zMmwxNjAgMCAwLTI5NC43Yy0yMy41LTEwLjMtNDEuMi0zMS42LTQ2LjQtNTcuM0wxMjggOTZjLTE3LjcgMC0zMi0xNC4zLTMyLTMyczE0LjMtMzIgMzItMzJsMTI4IDBjMTQuNi0xOS40IDM3LjgtMzIgNjQtMzJzNDkuNCAxMi42IDY0IDMyem01NS42IDI4OGwxNDQuOSAwTDUxMiAxOTUuOCA0MzkuNiAzMjB6TTUxMiA0MTZjLTYyLjkgMC0xMTUuMi0zNC0xMjYtNzguOWMtMi42LTExIDEtMjIuMyA2LjctMzIuMWw5NS4yLTE2My4yYzUtOC42IDE0LjItMTMuOCAyNC4xLTEzLjhzMTkuMSA1LjMgMjQuMSAxMy44bDk1LjIgMTYzLjJjNS43IDkuOCA5LjMgMjEuMSA2LjcgMzIuMUM2MjcuMiAzODIgNTc0LjkgNDE2IDUxMiA0MTZ6TTEyNi44IDE5NS44TDU0LjQgMzIwbDE0NC45IDBMMTI2LjggMTk1Ljh6TS45IDMzNy4xYy0yLjYtMTEgMS0yMi4zIDYuNy0zMi4xbDk1LjItMTYzLjJjNS04LjYgMTQuMi0xMy44IDI0LjEtMTMuOHMxOS4xIDUuMyAyNC4xIDEzLjhsOTUuMiAxNjMuMmM1LjcgOS44IDkuMyAyMS4xIDYuNyAzMi4xQzI0MiAzODIgMTg5LjcgNDE2IDEyNi44IDQxNlMxMS43IDM4MiAuOSAzMzcuMXoiLz48L3N2Zz4%3D)

TypedCache is a lightweight, type-safe façade around your favourite Ruby cache
stores. It adds three things on top of the raw back-end implementation:

1. **Namespacing** – hierarchical `Namespace` helpers prevent key collisions. You can create nested namespaces easily, like `Namespace.at("users", "profiles", "avatars")`.
2. **Stronger types** – RBS signatures as well as monadic types like `Either`, `Maybe`, and `Snapshot` wrap cache results so you always know whether you have a value, an error, or a cache-miss.
3. **Composable decorators** – behaviours like instrumentation can be layered
   on without touching the underlying store.

> **TL;DR** – Think _Faraday_ or _Rack_ middlewares, but for caching.

---

## Installation

```bash
bundle add typed_cache && bundle install
# or
gem install typed_cache
```

This gem does is also cryptographically signed, if you want to ensure the gem was not tampered with, make sure to use these commands:

```bash
bundle add typed_cache && bundle install --trust-policy=HighSecurity
# or
gem install typed_cache -P HighSecurity
```

If there are issues with unsigned gems, use `MediumSecurity` instead.

## Quick start

```ruby
require "typed_cache"

# 1. Build a store
store = TypedCache.builder
  .with_backend(:memory, shared: true)
  .with_instrumentation(:rails) # e.g. using ActiveSupport
  .build
  .value # unwrap Either for brevity

# 2. Get a reference to a key
user_ref = store.ref("users:123") # => CacheRef

# 3. Fetch and compute if absent
user_snapshot = user_ref.fetch do
  puts "Cache miss! Computing..."
  { id: 123, name: "Jane" }
end.value # => Snapshot

puts "Found: #{user_snapshot.value} (from_cache?=#{user_snapshot.from_cache?})"
```

## Builder API

| Step                            | Purpose                                                        |
| ------------------------------- | -------------------------------------------------------------- |
| `with_backend(:name, **opts)`   | Mandatory. Configure the concrete **Backend** and its options. |
| `with_decorator(:key)`          | Optional. Add a decorator by registry key.                     |
| `with_instrumentation(:source)` | Optional. Add instrumentation, e.g. `:rails` or `:dry`.        |
| `build`                         | Returns `Either[Error, Store]`.                                |

### Back-ends vs Decorators

- **Back-end** (`TypedCache::Backend`) – persists data (Memory, Redis, etc.).
- **Decorator** (`TypedCache::Decorator`) – wraps an existing store to add
  behaviour (Instrumentation, Logging, Circuit-Breaker …).

Both include the same public `Store` interface, so they can be composed
freely. Registries keep them separate:

```ruby
TypedCache::Backends.available   # => [:memory, :active_support]
TypedCache::Decorators.available # => [:instrumented]
```

### Register your own

```ruby
class RedisBackend
  include TypedCache::Backend
  # … implement #read, #write, etc.
end

TypedCache::Backends.register(:redis, RedisBackend)
```

```ruby
class LogDecorator
  include TypedCache::Decorator
  def initialize(store) = @store = store
  def write(key, value)
    puts "[cache] WRITE #{key}"
    @store.write(key, value)
  end
  # delegate the rest …
end

TypedCache::Decorators.register(:logger, LogDecorator)
```

## Error handling

All operations return one of:

- `Either.right(Snapshot)` – success
- `Either.left(CacheMissError)` – key not present
- `Either.left(StoreError)` – transport / serialization failure

Use the monad directly or pattern-match:

```ruby
result.fold(
  ->(err)      { warn err.message },
  ->(snapshot) { puts snapshot.value },
)
```

## The `CacheRef` and `Store` APIs

While you can call `read`, `write`, and `fetch` directly on the `store`, the more powerful way to work with TypedCache is via the `CacheRef` object. It provides a rich, monadic API for a single cache key. The `Store` also provides `fetch_all` for batch operations.

You get a `CacheRef` by calling `store.ref(key)`:

```ruby
user_ref = store.ref("users:123") # => #<TypedCache::CacheRef ...>
```

Now you can operate on it:

```ruby
# Fetch a value, computing it if it's missing
snapshot_either = user_ref.fetch do
  { id: 123, name: "Jane Doe" }
end

# The result is always an Either[Error, Snapshot]
snapshot_either.fold(
  ->(err)      { warn "Something went wrong: #{err.message}" },
  ->(snapshot) { puts "Got value: #{snapshot.value} (from cache: #{snapshot.from_cache?})" }
)

# You can also map over values
name_either = user_ref.map { |user| user[:name] }
puts "User name is: #{name_either.value.value}" # unwrap Either, then Snapshot
```

### Batch Operations with `fetch_all`

For retrieving multiple keys at once, the `Store` provides a `fetch_all` method. This is more efficient than fetching keys one by one, especially with remote back-ends like Redis.

It takes a list of keys and a block to compute the values for any missing keys.

```ruby
user_refs = store.fetch_all("users:123", "users:456") do |missing_key|
  # This block is called for each cache miss
  user_id = missing_key.split(":").last
  puts "Cache miss for #{missing_key}! Computing..."
  { id: user_id, name: "Fetched User #{user_id}" }
end

user_refs.each do |key, snapshot_either|
  snapshot_either.fold(
    ->(err)      { warn "Error for #{key}: #{err.message}" },
    ->(snapshot) { puts "Got value for #{key}: #{snapshot.value}" }
  )
end
```

The `CacheRef` API encourages a functional style and makes composing cache operations safe and predictable.

## Instrumentation

TypedCache can publish events about cache operations using different instrumenters. To enable it, use the `with_instrumentation` method on the builder, specifying an instrumentation backend:

```ruby
# For ActiveSupport::Notifications (e.g. in Rails)
store = TypedCache.builder
  .with_backend(:memory)
  .with_instrumentation(:rails)
  .build.value

# For Dry::Monitor
store = TypedCache.builder
  .with_backend(:memory)
  .with_instrumentation(:dry)
  .build.value
```

Events are published to a topic like `typed_cache.<operation>` (e.g., `typed_cache.write`). The topic namespace can be configured.

Payload keys include: `:namespace, :key, :operation, :duration`, and `cache_hit`.

You can subscribe to these events like so:

```ruby
# Example for ActiveSupport
ActiveSupport::Notifications.subscribe("typed_cache.write") do |name, start, finish, id, payload|

# Or you can subscribe via the store object itself
instrumenter = store.instrumenter
instrumenter.subscribe("write") do |event|
  payload = event.payload
  puts "Cache WRITE for key #{payload[:key]} took #{payload[:duration]}ms. Hit? #{payload[:cache_hit]}"
end
```

If you call `with_instrumentation` with no arguments, it uses a `Null` instrumenter, which has no overhead.

### Custom Instrumenters

Just like with back-ends and decorators, you can write and register your own instrumenters. An instrumenter must implement an `instrument` and a `subscribe` method.

```ruby
class MyCustomInstrumenter
  include TypedCache::Instrumenter

  def instrument(operation, key, **payload, &block)
    # ... your logic ...
  end

  def subscribe(event_name, **filters, &block)
    # ... your logic ...
  end
end

# Register it
TypedCache::Instrumenters.register(:custom, MyCustomInstrumenter)

# Use it
store = TypedCache.builder
  .with_instrumentation(:custom)
  # ...
```

## Further examples

For more advanced scenarios—including Rails integration, pattern matching, custom back-ends, and testing—see [examples.md](examples.md).

## License

This work is licensed under the [Apache-2.0](./LICENSE) license.

### Apache 2.0 License Key Terms

#### Grants

- Perpetual, worldwide, non-exclusive, royalty-free license to:
  - Reproduce the work
  - Prepare derivative works
  - Distribute the work
  - Use and sell the work

#### Requirements

- Include a copy of the Apache 2.0 License with any distribution
- Provide attribution
- Clearly mark any modifications made to the original work
- Retain all original copyright and license notices

#### Permissions

- Commercial use allowed
- Modification permitted
- Distribution of original and modified work permitted
- Patent use granted
- Private use allowed

#### Limitations

- No warranty or liability protection
- Trademark rights not transferred
- Contributors not liable for damages

#### Compatibility

- Can be used in closed-source and commercial projects
- Requires preserving original license and attribution
