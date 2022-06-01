defmodule AppCountWeb.CategoryController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Categories"})
  end
end
