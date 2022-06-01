defmodule AppCountWeb.TaskController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
