defmodule AppCountWeb.API.InvoicingController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  authorize(["Accountant"])

  def index(conn, params) do
    json(conn, Accounting.list_invoicings(conn.assigns.admin, params))
  end
end
