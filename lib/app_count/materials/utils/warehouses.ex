defmodule AppCount.Materials.Utils.Warehouses do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Materials.Warehouse
  alias AppCount.Repo

  def list_warehouses() do
    from(
      w in Warehouse,
      left_join: s in assoc(w, :stocks),
      select: %{
        id: w.id,
        name: w.name,
        image: w.image,
        stocks: jsonize(s, [:id, :name, :image])
      },
      group_by: [w.id]
    )
    |> Repo.all()
  end

  def create_warehouse(params) do
    %Warehouse{}
    |> Warehouse.changeset(params)
    |> Repo.insert()
  end

  def update_warehouse(id, params) do
    Repo.get(Warehouse, id)
    |> Warehouse.changeset(params)
    |> Repo.update()
  end
end
