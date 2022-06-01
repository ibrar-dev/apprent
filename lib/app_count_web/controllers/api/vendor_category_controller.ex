defmodule AppCountWeb.API.VendorCategoryController do
  use AppCountWeb, :controller
  alias AppCount.Vendors

  def index(conn, _params) do
    json(conn, Vendors.list_categories())
  end

  def create(conn, %{"category" => params}) do
    Vendors.create_category(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "category" => params}) do
    Vendors.update_category(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Vendors.delete_category(id)
    json(conn, %{})
  end
end
