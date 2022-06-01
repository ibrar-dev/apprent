defmodule AppCountWeb.API.JournalPageController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  authorize(["Accountant"], index: ["Accountant", "Agent", "Admin"])

  def index(conn, _params) do
    json(conn, Accounting.list_journal_pages())
  end

  def show(conn, %{"id" => id}) do
    journal = Accounting.get_journal(id)

    json(conn, %{
      id: journal.id,
      accrual: journal.accrual,
      cash: journal.cash,
      date: journal.date,
      name: journal.name
    })
  end

  def create(conn, %{"journal_page" => params}) do
    Accounting.create_journal_page(params)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "journal_page" => params}) do
    Accounting.update_journal_page(id, params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Accounting.delete_journal_page(id)
    json(conn, %{})
  end
end
