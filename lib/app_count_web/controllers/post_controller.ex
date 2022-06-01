defmodule AppCountWeb.PostController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Residents Social"})
  end
end
