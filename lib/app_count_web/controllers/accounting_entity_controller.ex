defmodule AppCountWeb.AccountingEntityController do
  use AppCountWeb, :controller

  authorize(["Accountant"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Accounting Entities"})
  end
end
