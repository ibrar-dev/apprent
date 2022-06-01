defmodule AppCountWeb.LeaseController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Leases"})
  end

  def new(conn, %{"id" => id}) do
    render(conn, "new.html", %{title: "Transfer/Renewal", lease_id: id})
  end

  def show(conn, %{"id" => id}) do
    case AppCount.Leases.document_url(id) do
      nil -> text(conn, "No document found")
      url -> redirect(conn, external: url)
    end
  end
end
