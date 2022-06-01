defmodule AppCountWeb.CardController do
  use AppCountWeb, :controller

  def index(conn, params) do
    render(conn, "index.html", %{title: "Make Ready Board", legacy: !!params["legacy"]})
  end
end
