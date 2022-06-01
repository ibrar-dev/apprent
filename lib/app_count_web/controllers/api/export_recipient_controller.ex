defmodule AppCountWeb.API.ExportRecipientController do
  use AppCountWeb, :controller
  alias AppCount.Exports

  def index(conn, _params) do
    json(conn, Exports.list_recipients(conn.assigns.admin.id))
  end

  def create(conn, %{"recipient" => params}) do
    {:ok, recipient} =
      params
      |> Map.put("admin_id", conn.assigns.admin.id)
      |> Exports.insert_recipient()

    json(conn, %{recipient: Map.take(recipient, [:name, :email, :id])})
  end

  def delete(conn, %{"id" => id}) do
    Exports.delete_recipient(id)
    |> handle_error(conn)
  end
end
