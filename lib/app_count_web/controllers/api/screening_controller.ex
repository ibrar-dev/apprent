defmodule AppCountWeb.API.ScreeningController do
  use AppCountWeb, :controller
  alias AppCount.RentApply
  alias AppCount.Leases

  def create(conn, %{"application" => params}) do
    %{"id" => application_id, "rent" => rent} = params

    RentApply.screen_application(application_id, rent, conn.assigns.client_schema)
    |> handle_error(conn)
  end

  def create(conn, %{"screening" => params}) do
    Leases.create_screening(params, false, conn.assigns.client_schema)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "approve" => _}) do
    Leases.approve_screening(id)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id}) do
    Leases.get_screening_status(id)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Leases.delete_screening(id)
    |> handle_error(conn)
  end
end
