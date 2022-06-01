defmodule AppCountWeb.VendorController do
  use AppCountWeb, :controller
  authorize(["Admin", "Agent", "Tech"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Vendors"})
  end
end
