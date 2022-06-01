defmodule AppCountWeb.PageController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Pages"})
  end
end
