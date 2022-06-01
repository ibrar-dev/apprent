defmodule AppCountWeb.API.LeaseFormController do
  use AppCountWeb, :controller
  alias AppCount.Leases

  def create(conn, %{"lease_form" => params}) do
    Leases.create_form_from_bluemoon(params)
    |> handle_error(conn)
  end
end
