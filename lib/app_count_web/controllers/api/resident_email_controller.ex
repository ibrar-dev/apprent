defmodule AppCountWeb.API.ResidentEmailController do
  use AppCountWeb, :controller
  alias AppCount.Tenants

  def create(conn, %{"resident_email" => params}) do
    Tenants.send_individual_email(params)
    json(conn, %{})
  end
end
