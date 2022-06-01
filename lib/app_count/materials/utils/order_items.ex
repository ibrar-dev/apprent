defmodule AppCount.Materials.Utils.OrderItems do
  import Ecto.Query
  alias AppCount.Materials.OrderItem
  alias AppCount.Repo

  def list_items_in_cart(stock_id) do
    from(
      i in OrderItem,
      join: m in assoc(i, :material),
      select: %{
        id: i.id,
        name: m.name,
        status: i.status,
        cost: i.cost,
        quantity: i.quantity
      },
      where: m.stock_id == ^stock_id and i.status == "pending",
      group_by: [m.stock_id, m.id, i.id]
    )
    |> Repo.all()
  end

  def create_item(params) do
    %OrderItem{}
    |> OrderItem.changeset(params)
    |> Repo.insert!()
  end

  def update_item(id, params) do
    Repo.get(OrderItem, id)
    |> OrderItem.changeset(params)
    |> Repo.update()
  end
end
