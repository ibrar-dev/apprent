defmodule AppCountWeb.PurchaseController do
  use AppCountWeb, :controller

  authorize(["Admin"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Purchases"})
  end
end
