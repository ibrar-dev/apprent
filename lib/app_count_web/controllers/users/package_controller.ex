defmodule AppCountWeb.Users.PackageController do
  use AppCountWeb.Users, :controller
  alias AppCount.Properties

  def index(conn, _params) do
    packages = Properties.list_resident_packages(conn.assigns.user.id)
    render(conn, "index.html", packages: packages)
  end
end
