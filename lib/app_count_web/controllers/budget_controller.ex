defmodule AppCountWeb.BudgetController do
  use AppCountWeb, :controller

  def index(conn, _) do
    render(conn, "index.html", %{title: "Budgets"})
  end
end
