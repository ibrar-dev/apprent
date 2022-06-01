defmodule AppCountWeb.ClosingController do
  use AppCountWeb, :controller

  authorize(["Accountant"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Month Closings"})
  end
end
