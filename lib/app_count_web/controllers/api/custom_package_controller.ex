defmodule AppCountWeb.API.CustomPackageController do
  use AppCountWeb, :controller
  alias AppCount.Leasing.Utils.CustomPackages

  def create(conn, %{"custom_package" => params}) do
    CustomPackages.create_custom_package(params)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "custom_package" => params}) do
    CustomPackages.update_custom_package(id, params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    CustomPackages.delete_custom_package(id)
    json(conn, %{})
  end
end
