defmodule AppCountWeb.API.ChargeCodeController do
  use AppCountWeb, :controller
  alias AppCount.Core.ClientSchema
  alias AppCount.Ledgers.Utils.ChargeCodes

  authorize(["Accountant"])

  def index(conn, _params) do
    json(conn, ChargeCodes.list(ClientSchema.new(conn.assigns.client_schema)))
  end

  def create(conn, %{"charge_code" => params}) do
    ClientSchema.new(conn.assigns.client_schema, params)
    |> ChargeCodes.insert_charge_code()
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "charge_code" => params}) do
    ClientSchema.new(conn.assigns.client_schema, id)
    |> ChargeCodes.update_charge_code(params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    ChargeCodes.delete_charge_code(
      ClientSchema.new(conn.assigns.client_schema, String.to_integer(id))
    )
    |> handle_error(conn)
  end
end
