defmodule AppCountWeb.API.EmailController do
  use AppCountWeb, :controller
  require Logger

  def create(conn, %{text: text}) do
    AppCount.Mail.process_mail(text)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Got it")
  end
end
