defmodule AppCountWeb.FeatureController do
  use AppCountWeb, :controller
  authorize(["Admin"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Unit Features"})
  end
end
