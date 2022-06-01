defmodule AppCount.Data.PersistentState do
  @moduledoc """
    For use whenever we have a stateful GenServer when it is important
    to preserve the GenServer state in the event of a crash or a deploy.

    Basically just provides some convenience functions and ensures
    that we do not end up with 2 modules using the same cache key
  """
  alias AppCount.Data.CacheRepo

  defmacro __using__(_) do
    quote do
      @__cache_key__ "#{__MODULE__}"
      @persister Application.compile_env(:app_count, :state_cache, AppCount.Data.PersistentState)

      def fetch_state() do
        @persister.fetch(@__cache_key__)
      end

      def persist_state(state) do
        @persister.persist(@__cache_key__, state)
      end
    end
  end

  def persist(key, state) do
    CacheRepo.set(key, state)
    state
  end

  def fetch(key), do: CacheRepo.get(key)
end
