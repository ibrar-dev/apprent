defmodule AppCount.Materials.Utils.Inventories do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Materials.Inventory
  alias AppCount.Materials.Stock
  alias AppCount.Materials.Material

  def convert_stocks_to_inventory() do
    from(
      s in Stock,
      select: s.id
    )
    |> Repo.all()
    |> Enum.each(fn stock_id -> convert_stock(stock_id) end)
  end

  def convert_stock(stock_id) do
    from(
      m in Material,
      where: m.stock_id == ^stock_id,
      select: %{
        material_id: m.id,
        stock_id: m.stock_id,
        inventory: m.inventory
      }
    )
    |> Repo.all()
    |> Enum.each(fn m -> create_inventory(m) end)
  end

  def create_inventory(params) do
    %Inventory{}
    |> Inventory.changeset(params)
    |> Repo.insert!()
  end

  def update_inventory(id, params) do
    Repo.get(Inventory, id)
    |> Inventory.changeset(params)
    |> Repo.update!()
  end

  def delete_inventory(id) do
    Repo.get(Inventory, id)
    |> Repo.delete!()
  end

  def clear_items_in_stock(stock_id) do
    from(
      i in Inventory,
      where: i.stock_id == ^stock_id,
      select: i.id
    )
    |> Repo.all()
    |> Enum.each(fn x -> delete_inventory(x) end)
  end

  def duplicate_inventory(id1, id2) do
    from(
      i in Inventory,
      where: i.stock_id == ^id1,
      select: %{
        material_id: i.material_id,
        inventory: i.inventory
      }
    )
    |> Repo.all()
    |> Enum.each(fn x -> Map.put(x, :stock_id, id2) |> create_inventory end)
  end
end
