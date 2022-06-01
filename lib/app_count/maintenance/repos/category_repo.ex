defmodule AppCount.Maintenance.CategoryRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Maintenance.Category,
    preloads: [:parent]

  def list(client_schema) do
    @schema
    |> Repo.all(prefix: client_schema)
    |> Repo.preload(@preloads)
  end
end
