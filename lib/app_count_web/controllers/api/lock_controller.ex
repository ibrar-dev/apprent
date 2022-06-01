defmodule AppCountWeb.API.LockController do
  use AppCountWeb, :controller
  alias AppCount.Accounts

  def create(conn, %{"lock" => params}) do
    params
    |> Map.put("admin_id", conn.assigns.admin.id)
    |> Accounts.create_lock()

    json(conn, %{})
  end

  def update(conn, %{"id" => id, "lock" => params}) do
    Accounts.update_lock(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Accounts.delete_lock(id)
    json(conn, %{})
  end
end
