defmodule AppCountWeb.API.ClosingController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  authorize(["Accountant"])

  def index(conn, _params) do
    json(conn, Accounting.list_closings(conn.assigns.admin))
  end

  def create(conn, %{"closing" => params}) do
    Accounting.create_closing(conn.assigns.admin, params)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "closing" => params}) do
    Accounting.update_closing(conn.assigns.admin, id, params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Accounting.delete_closing(conn.assigns.admin, id)
    json(conn, %{})
  end
end
