defmodule AppCountWeb.Users.API.V1.PropertyController do
  use AppCountWeb.Users, :controller
  alias AppCount.Properties

  def index(conn, _) do
    json(conn, Properties.property_info(conn.assigns.user.property.id))
  end
end
