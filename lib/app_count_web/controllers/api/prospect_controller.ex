defmodule AppCountWeb.API.ProspectController do
  use AppCountWeb, :controller
  alias AppCount.Prospects
  authorize(["Admin", "Agent"])

  def index(conn, _params) do
    json(conn, Prospects.list_prospects(conn.assigns.admin))
  end

  def create(conn, %{"prospect" => params}) do
    params
    |> Map.merge(%{"admin_id" => conn.assigns.admin.id, "contact_date" => AppCount.current_time()})
    |> Prospects.create_prospect()
    |> handle_error(conn)
  end

  def create(conn, %{"memo" => params}) do
    params
    |> Map.put("admin", conn.assigns.admin.name)
    |> Prospects.create_memo()
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "prospect" => params}) do
    Prospects.update_prospect(id, params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Prospects.delete_prospect(id)
    |> handle_error(conn)
  end
end
