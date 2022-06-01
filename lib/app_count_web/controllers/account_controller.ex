defmodule AppCountWeb.AccountController do
  use AppCountWeb, :controller

  authorize(["Accountant"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Accounts"})
  end
end
