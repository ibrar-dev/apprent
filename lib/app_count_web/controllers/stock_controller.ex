defmodule AppCountWeb.StockController do
  use AppCountWeb, :controller
  alias AppCount.Materials

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Stocks"})
  end

  def show(conn, %{"id" => id, "action" => action}) when action in ["print"] do
    apply(__MODULE__, String.to_atom(action), [conn, id])
  end

  def print(conn, stock_id) do
    conn
    |> put_layout(false)
    |> render("print.html", materials: Materials.print_stock(stock_id))
  end
end
