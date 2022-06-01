defmodule AppCountWeb.Users.API.V1.EventController do
  use AppCountWeb.Users, :controller
  alias AppCount.Properties

  def index(conn, _params) do
    events = Properties.list_resident_events(conn.assigns.user.property.id)
    json(conn, %{events: events})
  end
end
