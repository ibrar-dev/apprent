defmodule AppCountWeb.LetterController do
  use AppCountWeb, :controller

  def index(conn, _) do
    render(conn, "index.html", %{title: "Letter Generation"})
  end
end
