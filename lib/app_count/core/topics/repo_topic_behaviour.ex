defmodule AppCount.Core.RepoTopicBehaviour do
  @callback created(Map.t(), atom()) :: AppCount.Core.DomainEvent.t()
  @callback changed(Map.t(), atom()) :: AppCount.Core.DomainEvent.t()
  @callback deleted(Map.t(), atom()) :: AppCount.Core.DomainEvent.t()
end
