defmodule AppCountWeb.API.ResidentEventController do
  use AppCountWeb, :controller
  alias AppCount.Properties

  def index(conn, %{"property_id" => property_id, "upcoming" => _}) do
    safe_json(conn, Properties.list_resident_events(property_id, :upcoming))
  end

  def index(conn, %{"property_id" => property_id}) do
    safe_json(conn, Properties.list_resident_events(property_id))
  end

  def show(conn, %{"id" => id}) do
    safe_json(conn, Properties.show_resident_event(id))
  end

  def create(conn, %{"resident_event" => params}) do
    new_params = Map.put(params, "admin", conn.assigns.admin.name)

    case Properties.create_resident_event(new_params) do
      {:ok, _} -> safe_json(conn, %{})
    end
  end

  def update(conn, %{"id" => id, "resident_event" => params}) do
    Properties.update_resident_event(id, params)
    safe_json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_resident_event(id)
    json(conn, %{})
  end
end
