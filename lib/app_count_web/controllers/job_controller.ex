defmodule AppCountWeb.JobController do
  use AppCountWeb, :controller
  authorize([])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Jobs"})
  end
end
