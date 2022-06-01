defmodule AppCountWeb.PaymentController do
  use AppCountWeb, :controller

  authorize(["Accountant", "Admin", "Agent"])

  def index(conn, _params) do
    render(conn, "index.html", title: "Payments")
  end
end
