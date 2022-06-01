defmodule AppCountWeb.ChargeCodeController do
  use AppCountWeb, :controller

  authorize(["Accountant"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Charge Codes"})
  end
end
