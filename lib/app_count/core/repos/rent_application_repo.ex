defmodule AppCount.Core.RentApplicationRepo do
  import Ecto.Repo
  alias AppCount.Repo
  @schema AppCount.RentApply.RentApplication

  def get_aggregate(id, _preloads \\ []) when is_integer(id) do
    Repo.get(@schema, id)
    |> Repo.preload([:tenant, :persons])
  end
end
