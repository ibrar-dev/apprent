defmodule AppCountWeb.API.LeaseChargeController do
  use AppCountWeb, :controller
  alias AppCount.Leasing.Utils.Charges
  alias AppCount.Core.ClientSchema

  def create(conn, %{"charges" => params, "lease_id" => lease_id}) do
    Charges.update_charges(ClientSchema.new(conn.assigns.admin), lease_id, params)
    |> handle_error(conn)
  end
end
