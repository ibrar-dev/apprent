defmodule AppCountWeb.API.PetController do
  use AppCountWeb, :controller
  alias AppCount.Tenants

  def create(conn, %{"pet" => params}) do
    Tenants.create_pet({conn.assigns.client_schema, params})
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "pet" => params}) do
    Tenants.update_pet({conn.assigns.client_schema, id}, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Tenants.delete_pet({conn.assigns.client_schema, conn.assigns.admin}, id)

    json(conn, %{})
  end
end
