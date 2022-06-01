defmodule AppCount.Properties.Utils.Regions do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Properties.Region

  def create(params) do
    %Region{}
    |> Region.changeset(params)
    |> Repo.insert()
  end

  def update(id, params) do
    Repo.get(Region, id)
    |> Region.changeset(params)
    |> Repo.update()
  end

  def list_regions() do
    from(
      r in Region,
      select: map(r, [:id, :name])
    )
    |> Repo.all()
  end
end
