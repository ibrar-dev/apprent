defmodule AppCountWeb.API.AccountController do
  use AppCountWeb, :controller
  alias AppCount.Accounting
  alias AppCount.Core.ClientSchema

  authorize(["Accountant"], index: ["Accountant", "Agent", "Admin"])

  def index(conn, %{"categories" => _}) do
    json(conn, Accounting.account_tree())
  end

  def index(conn, _params) do
    json(conn, Accounting.list_accounts(ClientSchema.new(conn.assigns.client_schema)))
  end

  def create(conn, %{"account" => params}) do
    Accounting.create_account(ClientSchema.new(conn.assigns.client_schema, params))
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "account" => params}) do
    Accounting.update_account(id, ClientSchema.new(conn.assigns.client_schema, params))
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Accounting.delete_account(
      ClientSchema.new(conn.assigns.client_schema, conn.assigns.admin),
      id
    )
    |> handle_error(conn)
  end
end
