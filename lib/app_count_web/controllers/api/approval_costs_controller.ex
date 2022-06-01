defmodule AppCountWeb.API.ApprovalCostsController do
  use AppCountWeb, :controller
  alias AppCount.Approvals

  def show(conn, %{"id" => id, "property_id" => property_id}) do
    json(conn, Approvals.get_spent(id, property_id))
  end

  def index(conn, %{"chart_data" => _, "property_id" => property_id, "admin_id" => admin_id}) do
    admin =
      if admin_id do
        %{id: admin_id}
      else
        conn.assigns.admin
      end

    json(conn, Approvals.chart_data(admin, property_id))
  end
end
