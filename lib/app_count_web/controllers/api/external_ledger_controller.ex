defmodule AppCountWeb.API.ExternalLedgerController do
  use AppCountWeb, :controller
  alias AppCount.Leases.ExternalLedgerBoundary

  def show(conn, %{"external_id" => external_id}) do
    if ExternalLedgerBoundary.can_access(conn.assigns.admin, external_id) do
      json(conn, ExternalLedgerBoundary.ledger_details(external_id))
    else
      conn
      |> put_status(401)
      |> json("Unauthorized Access")
    end
  end
end
