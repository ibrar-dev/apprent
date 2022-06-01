defmodule AppCountWeb.TimecardController do
  use AppCountWeb, :controller
  authorize(["Accountant", "Tech"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Hours"})
  end
end
