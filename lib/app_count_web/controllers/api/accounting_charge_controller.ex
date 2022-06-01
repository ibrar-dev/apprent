defmodule AppCountWeb.API.AccountingChargeController do
  use AppCountWeb, :controller
  alias AppCount.Ledgers.Utils.Charges
  alias AppCount.Core.ClientSchema

  def create(conn, %{"charges" => params}) do
    Enum.each(params, fn charge ->
      ClientSchema.new(
        conn.assigns.client_schema,
        Map.merge(charge, %{"status" => "manual", "admin" => conn.assigns.admin.name})
      )
      |> Charges.create_charge()
    end)

    json(conn, %{})
  end

  def create(conn, %{"property_id" => property_id, "data" => csv}) do
    json(conn, %{
      imported: Charges.import_csv(ClientSchema.new(conn.assigns.client_schema, property_id), csv)
    })
  end

  def create(conn, %{"batch_charges" => charges, "date" => date, "lease_id" => lease_id}) do
    Charges.create_batch_charges(
      ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin.name),
      charges,
      %{
        "bill_date" => date,
        "lease_id" => lease_id
      }
    )

    json(conn, %{})
  end

  def create(conn, %{"batch" => params}) do
    Charges.create_batch_charges(
      ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin.name),
      params
    )

    json(conn, %{})
  end

  def show(conn, %{"id" => lease_id, "date" => date}) do
    json(conn, Charges.list_prorate_charges(lease_id, date))
  end

  def update(conn, %{"id" => id, "charge" => params}) do
    Charges.update_charge(id, ClientSchema.new(conn.assigns.client_schema, params))
    json(conn, %{})
  end

  def delete(conn, %{"id" => id, "destroy" => _}) do
    case Charges.delete_charge(
           ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
           id
         ) do
      {:error, :unauthorized} ->
        conn
        |> put_status(403)
        |> json(%{})

      _ ->
        json(conn, %{})
    end
  end

  def delete(conn, %{"id" => id, "date" => date, "post_month" => pm}) do
    Charges.reverse_charge(
      ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
      id,
      %{date: date, post_month: pm}
    )

    json(conn, %{})
  end
end
