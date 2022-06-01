defmodule AppCountWeb.ApprovalController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Approvals"})
  end
end
