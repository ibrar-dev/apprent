defmodule AppCountWeb.API.SavedFormAdminController do
  use AppCountWeb, :controller
  alias AppCount.RentApply
  authorize(["Admin", "Agent"])

  def index(conn, %{"property_id" => property_id}) do
    applications =
      RentApply.list_saved_forms(
        conn.assigns.admin,
        %{property_id: property_id}
      )

    json(conn, %{applications: applications})
  end
end
