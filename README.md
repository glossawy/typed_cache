# TypedCache

TypedCache is a lightweight, type-safe façade around your favourite Ruby cache
stores. It adds three things on top of the raw back-end implementation:

1. **Namespacing** – hierarchical `Namespace` helpers prevent key collisions.
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

# Build an in-memory cache with ActiveSupport-style instrumentation
store = TypedCache.builder
            .with_backend(:memory, shared: true)
            .with_instrumentation      # or .with_decorator(:instrumented)
            .build                     # => Either[Error, Store]
            .value

users_key   = store.namespace.key("users")   # => CacheKey
snapshot    = store.set(users_key, [1, 2, 3]) # => Either[Error, Snapshot]
puts snapshot.value           # => [1, 2, 3]
```

## Builder API

| Step                          | Purpose                                                        |
| ----------------------------- | -------------------------------------------------------------- |
| `with_backend(:name, **opts)` | Mandatory. Configure the concrete **Backend** and its options. |
| `with_decorator(:key)`        | Optional. Add a decorator by registry key.                     |
| `with_instrumentation`        | Convenience alias for `with_decorator(:instrumented)`.         |
| `build`                       | Returns `Either[Error, Store]`.                                |

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
  # … implement #get, #set, etc.
end

TypedCache::Backends.register(:redis, RedisBackend)
```

```ruby
class LogDecorator
  include TypedCache::Decorator
  def initialize(store) = @store = store
  def set(key, value)
    puts "[cache] SET #{key}"
    @store.set(key, value)
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

## Instrumentation

Decorators publish ActiveSupport notifications when
`TypedCache.config.instrumentation.enabled = true`:

```
<operation>.<namespace>  # e.g. get.typed_cache
```

Payload keys: `:namespace, :key, :duration, :cache_hit`, …

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
