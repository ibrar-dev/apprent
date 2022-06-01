defmodule AppCountWeb.MailingController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Mailing Tool"})
  end
end
