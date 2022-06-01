defmodule AppCountWeb.API.BankAccountController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  authorize(["Accountant"])

  def index(conn, %{"property_id" => property_id}) do
    json(conn, Accounting.list_bank_accounts(property_id))
  end

  def index(conn, _params) do
    json(conn, Accounting.list_bank_accounts())
  end

  def create(conn, %{"bank_account" => params}) do
    Accounting.create_bank_account(params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "bank_account" => params}) do
    Accounting.update_bank_account(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Accounting.delete_bank_account(conn.assigns.admin, id)
    json(conn, %{})
  end
end
