defmodule AppCountWeb.API.LeaseRenewalController do
  use AppCountWeb, :controller
  alias AppCount.Leases
  alias AppCount.Leasing.Utils.RenewalPeriods
  alias AppCount.Leasing.Utils.RenewalPackages
  alias AppCount.Leasing.Utils.CustomPackages
  alias AppCount.Core.ClientSchema

  authorize(["Regional", "Accountant"], index: ["Agent", "Admin"], show: ["Agent", "Admin"])

  def index(conn, %{"report" => _, "property_id" => property_id}) do
    json(conn, Leases.renewal_report(conn.assigns.admin, property_id))
  end

  def index(
        conn,
        %{
          "valid_dates" => _,
          "start_date" => start_date,
          "end_date" => end_date,
          "property_id" => property_id
        }
      ) do
    json(
      conn,
      RenewalPeriods.check_if_valid_period(
        ClientSchema.new(conn.assigns.client_schema, property_id),
        start_date,
        end_date
      )
    )
  end

  def update(conn, %{"id" => _, "add_note" => add_note}) do
    conn.assigns.admin
    |> add_note(add_note)
    |> case do
      {:ok, _} -> json(conn, %{})
      {:error, e} -> json(conn, e)
    end
  end

  defp add_note(admin, %{"module" => "period", "id" => id, "note" => text}) do
    RenewalPeriods.add_note(ClientSchema.new(admin.client_schema, id), text, admin)
  end

  defp add_note(admin, %{"module" => "package", "id" => id, "note" => text}) do
    RenewalPackages.add_note(ClientSchema.new(admin.client_schema, id), text, admin)
  end

  defp add_note(admin, %{"module" => "custom_package", "id" => id, "note" => text}) do
    CustomPackages.add_note(ClientSchema.new(admin.client_schema, id), text, admin)
  end
end
