defmodule AppCountWeb.API.AccountCategoryController do
  use AppCountWeb, :controller
  alias AppCount.Accounting
  authorize(["Super Admin", "Accountant"], index: ["Accountant", "Agent", "Admin"])

  def create(conn, %{"account_category" => params}) do
    Accounting.create_category(params)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "account_category" => params}) do
    Accounting.update_category(id, params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Accounting.delete_category(id)
    json(conn, %{})
  end
end
