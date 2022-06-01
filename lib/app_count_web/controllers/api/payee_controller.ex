defmodule AppCountWeb.API.PayeeController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  authorize(["Accountant"],
    index: ["Admin", "Agent", "Tech", "Regional", "Super Admin"],
    create: ["Admin", "Agent", "Tech", "Regional", "Super Admin"]
  )

  def index(conn, %{"meta" => _}) do
    json(conn, Accounting.list_payees(:meta))
  end

  def index(conn, _params) do
    json(conn, Accounting.list_payees())
  end

  def create(conn, %{"payee" => params}) do
    Accounting.create_payee(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "payee" => params}) do
    Accounting.update_payee(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Accounting.delete_payee(id)
    json(conn, %{})
  end
end
