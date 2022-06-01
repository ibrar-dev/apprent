defmodule AppCountWeb.API.VendorController do
  use AppCountWeb, :controller
  alias AppCount.Vendors

  def index(conn, _params) do
    json(conn, Vendors.list_vendors(conn.assigns.admin))
  end

  def create(conn, %{"vendor" => params}) do
    Vendors.create_vendor(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "vendor" => params}) do
    Vendors.update_vendor(id, params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "delete" => params}) do
    Vendors.update_vendor(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Vendors.delete_vendor(id)
    json(conn, %{})
  end
end
