# frozen_string_literal: true

module TypedCache
  # Marker mixin for concrete cache back-ends.
  # A Backend *is* a Store, but the reverse is not necessarily true (decorators also
  # include Store). By tagging back-ends with this module we can type-check and
  # register them separately from decorators.
  #
  # Back-ends should *not* assume they wrap another store – they are the leaf nodes
  # that actually persist data.
  # @rbs generic V
  module Backend
    include Store #[V]
    # @rbs! include Store::_Store[V]
  end
end
