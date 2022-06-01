defmodule AppCountWeb.API.RewardTypeController do
  use AppCountWeb, :controller
  alias AppCount.Rewards

  def index(conn, _params) do
    json(conn, %{types: Rewards.list_types()})
  end

  def create(conn, %{"type" => params}) do
    Rewards.create_type(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "type" => params}) do
    Rewards.update_type(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Rewards.delete_type(id)
    json(conn, %{})
  end
end
