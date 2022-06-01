defmodule AppCountWeb.API.RegisterController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  authorize(["Admin"])

  def create(conn, %{"register" => params}) do
    Accounting.create_register(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "register" => params}) do
    Accounting.update_register(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Accounting.delete_register(id)
    json(conn, %{})
  end
end
