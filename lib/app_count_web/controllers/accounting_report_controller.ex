defmodule AppCountWeb.AccountingReportController do
  use AppCountWeb, :controller

  authorize(["Accountant", "Admin", "Regional"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Reports"})
  end
end
