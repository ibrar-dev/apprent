defmodule AppCountWeb.PackageController do
  use AppCountWeb, :controller
  authorize(["Admin", "Agent", "Tech"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Packages"})
  end
end
