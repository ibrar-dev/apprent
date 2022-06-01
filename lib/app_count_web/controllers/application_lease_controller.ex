defmodule AppCountWeb.ApplicationLeaseController do
  use AppCountWeb, :controller
  alias AppCount.Leases

  def show(conn, %{"id" => id}) do
    {:ok, pdf_data} = Leases.signature_pdf(id)

    conn
    |> put_resp_content_type("application/pdf")
    |> send_resp(conn.status || 200, Base.decode64!(pdf_data))
  end
end
