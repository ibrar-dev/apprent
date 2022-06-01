defmodule AppCountWeb.ExportController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "My Exports"})
  end
end
