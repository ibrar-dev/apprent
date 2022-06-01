defmodule AppCountWeb.API.BankController do
  use AppCountWeb, :controller
  alias AppCount.Settings

  authorize(["Super Admin"])

  def index(conn, _params) do
    json(conn, Settings.list_banks())
  end

  def create(conn, %{"bank" => params}) do
    Settings.create_bank(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "bank" => params}) do
    Settings.update_bank(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Settings.delete_bank(conn.assigns.admin, id)
    json(conn, %{})
  end
end
