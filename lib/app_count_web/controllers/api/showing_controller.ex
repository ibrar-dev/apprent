defmodule AppCountWeb.API.ShowingController do
  use AppCountWeb, :controller
  alias AppCount.Prospects

  def index(conn, _params) do
    json(conn, Prospects.list_showings(conn.assigns.admin))
  end

  def new(conn, %{"property_id" => prop_id}) do
    json(conn, Prospects.list_available(prop_id))
  end

  def create(conn, %{"showing" => %{"name" => _, "email" => _} = params}) do
    {:ok, prospect} =
      params
      |> Map.put("contact_date", AppCount.current_time())
      |> Map.put("contact_type", "Electronic")
      |> Prospects.create_prospect()

    params
    |> Map.put("prospect_id", prospect.id)
    |> Prospects.create_showing()
    |> handle_error(conn)
  end

  def create(conn, %{"showing" => params}) do
    params
    |> Prospects.create_showing()
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Prospects.delete_showing(id)
    json(conn, %{})
  end
end
