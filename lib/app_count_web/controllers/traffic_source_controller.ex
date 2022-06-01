defmodule AppCountWeb.TrafficSourceController do
  use AppCountWeb, :controller
  authorize(["Agent"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Traffic Sources"})
  end
end
