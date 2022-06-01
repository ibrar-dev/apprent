defmodule AppCountWeb.Users.API.V1.RenewalController do
  use AppCountWeb.Users, :controller
  alias AppCount.Core.ClientSchema

  def show(conn, %{"id" => id, "package_id" => package_id}) do
    AppCount.Leasing.Utils.RenewalPeriods.notify_pm_renewal(
      ClientSchema.new(conn.assigns.client_schema, id),
      conn.assigns.user.id,
      package_id
    )

    json(conn, %{})
  end

  def index(conn, _params) do
    json(conn, AppCount.Leasing.Utils.RenewalPeriods.find_lease_packages(conn.assigns.user.id))
  end
end
