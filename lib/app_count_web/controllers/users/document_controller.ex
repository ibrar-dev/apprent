defmodule AppCountWeb.Users.DocumentController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts

  def index(conn, _params) do
    documents = Accounts.get_documents(conn.assigns.user.id)
    render(conn, "index.html", documents: documents)
  end
end
