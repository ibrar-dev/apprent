defmodule AppCountWeb.PayeeController do
  use AppCountWeb, :controller

  authorize(["Accountant"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Payees"})
  end
end
