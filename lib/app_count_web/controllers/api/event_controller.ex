defmodule AppCountWeb.API.EventController do
  use AppCountWeb, :controller
  alias AppCount.Properties

  def index(conn, %{"property_id" => property_id}) do
    json(conn, Properties.list_events([property_id]))
  end

  def index(conn, _params) do
    json(conn, Properties.list_events(conn.assigns.user))
  end
end
