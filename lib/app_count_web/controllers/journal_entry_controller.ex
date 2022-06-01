defmodule AppCountWeb.JournalEntryController do
  use AppCountWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Journal Entry"})
  end

  #  def show(conn, %{"id" => id}) do
  #    redirect(conn, external: AppCount.Accounting.get_invoice(id).document_url.url)
  #  end
end
