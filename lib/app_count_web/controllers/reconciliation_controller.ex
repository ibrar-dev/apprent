defmodule AppCountWeb.ReconciliationController do
  use AppCountWeb, :controller

  authorize(["Accountant"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Reconcile"})
  end
end
