defmodule AppCountWeb.Users.API.V1.PackagesController do
  use AppCountWeb.Users, :controller
  alias AppCount.Properties

  def index(conn, _) do
    json(conn, Properties.list_resident_packages(conn.assigns.user.id))
  end
end
