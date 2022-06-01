defmodule AppCountWeb.EntityController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Entities"})
  end
end
