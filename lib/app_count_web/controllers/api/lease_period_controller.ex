defmodule AppCountWeb.API.LeasePeriodController do
  use AppCountWeb, :controller
  alias AppCount.Leasing.Utils.RenewalPeriods
  alias AppCount.Leasing.Utils.RenewalLetters
  alias AppCount.Core.ClientSchema

  def index(conn, %{"property_id" => property_id, "lease_id" => lease_id}) do
    json(
      conn,
      RenewalPeriods.find_lease_packages(
        ClientSchema.new(conn.assigns.admin),
        property_id,
        lease_id
      )
    )
  end

  def index(conn, %{"property_id" => property_id}) do
    json(conn, RenewalPeriods.list_renewal_periods(conn.assigns.admin, property_id))
  end

  def show(conn, %{"id" => id, "print" => _}) do
    conn
    |> put_resp_content_type("application/pdf")
    |> send_resp(200, RenewalPeriods.print_period_letters(id))
  end

  def create(conn, %{"period" => params}) do
    params
    |> Map.put("creator", conn.assigns.admin.name)
    |> RenewalPeriods.create_renewal_period()
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "approve" => _}) do
    result = RenewalPeriods.approve_renewal_period(ClientSchema.new(conn.assigns.admin), id)

    if elem(result, 0) == :ok,
      do: AppCount.Core.Tasker.start(fn -> RenewalLetters.generate(id) end)

    handle_error(result, conn)
  end

  def update(conn, %{"id" => id, "approval_request" => _}) do
    RenewalPeriods.notify_regional(conn.assigns.admin, id)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "period" => params}) do
    RenewalPeriods.update_renewal_period(id, params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    RenewalPeriods.delete_renewal_period(ClientSchema.new(conn.assigns.client_schema, id))
    json(conn, %{})
  end
end
