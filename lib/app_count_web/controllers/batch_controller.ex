defmodule AppCountWeb.BatchController do
  use AppCountWeb, :controller
  authorize(["Accountant"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Batch Charges"})
  end
end
