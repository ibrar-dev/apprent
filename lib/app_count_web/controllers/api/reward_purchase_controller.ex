defmodule AppCountWeb.API.RewardPurchaseController do
  use AppCountWeb, :controller
  alias AppCount.Rewards

  def index(conn, _params) do
    json(conn, %{purchases: Rewards.list_purchases(conn.assigns.admin)})
  end

  def update(conn, %{"id" => id, "purchase" => params}) do
    Rewards.update_purchase(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Rewards.delete_purchase(id)
    json(conn, %{})
  end
end
