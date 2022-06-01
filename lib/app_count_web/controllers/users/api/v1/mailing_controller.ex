defmodule AppCountWeb.Users.API.V1.MailingController do
  use AppCountWeb.Users, :controller
  alias AppCount.Messaging

  def index(conn, _) do
    json(conn, Messaging.list_emails(conn.assigns.user.id))
  end
end
