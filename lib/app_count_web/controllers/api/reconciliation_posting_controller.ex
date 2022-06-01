defmodule AppCountWeb.API.ReconciliationPostingController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  def index(conn, %{"bank_id" => bank_id}) do
    json(conn, Accounting.list_postings(bank_id))
  end

  def show(conn, %{"id" => posting_id, "filters" => filters}) do
    json(conn, Accounting.get_posting(posting_id, Poison.Parser.parse!(filters)))
  end

  def show(conn, %{"id" => posting_id, "pdf_report" => _}) do
    {:ok, data} = AppCount.Exports.Reconciliation.get_report(posting_id)

    send_download(
      conn,
      {:binary, data},
      content_type: "application/pdf",
      filename: "ReconciliationReport.pdf"
    )
  end

  def update(conn, %{"id" => id, "params" => params}) do
    Accounting.update_posting(id, params)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "params" => _, "undo_posting" => _}) do
    Accounting.undo_posting(id)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "params" => _, "post_reconciliation" => _}) do
    Accounting.post_reconciliation(id)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Accounting.delete_posting(id)
    |> handle_error(conn)
  end

  def create(conn, %{"params" => params}) do
    params = Map.put(params, "admin", conn.assigns.admin.name)

    Accounting.create_posting(params)
    |> handle_error(conn)
  end
end
