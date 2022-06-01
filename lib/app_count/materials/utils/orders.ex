defmodule AppCount.Materials.Utils.Orders do
  alias AppCount.Materials.Order
  alias AppCount.Repo

  def create_order(params) do
    %Order{}
    |> Order.changeset(params)
    |> Repo.insert!()
  end

  def update_order(id, params) do
    Repo.get(Order, id)
    |> Order.changeset(params)
    |> Repo.update()
  end
end
