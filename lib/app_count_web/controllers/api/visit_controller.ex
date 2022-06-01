defmodule AppCountWeb.API.VisitController do
  use AppCountWeb, :controller
  alias AppCount.Properties

  def index(conn, _params) do
    json(conn, Properties.list_visits(conn.assigns.admin))
  end

  def create(conn, %{"visit" => params}) do
    params
    |> Map.put("admin", conn.assigns.admin.name)
    |> Properties.create_visit()

    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_visit(id)
    json(conn, %{})
  end
end
