defmodule AppCountWeb.InvoiceController do
  use AppCountWeb, :controller

  authorize(["Accountant"])

  def index(conn, _params) do
    render(conn, "index.html", %{title: "Invoices"})
  end

  def show(conn, %{"id" => id}) do
    redirect(conn, external: AppCount.Accounting.get_invoice(id).document_url.url)
  end
end
