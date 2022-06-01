defmodule AppCountWeb.API.CheckController do
  use AppCountWeb, :controller
  alias AppCount.Accounting

  authorize(["Admin"])

  def index(conn, %{"pdf_ids" => pdf_ids}) do
    pdf_ids = String.split(pdf_ids, ",")
    render_check_template_fn = &AppCountWeb.LetterPreviewer.render_check_template/1
    html = Accounting.check_if_document_exists(pdf_ids, true, render_check_template_fn)
    json(conn, %{base64: html})
  end

  def index(conn, _params) do
    json(conn, Accounting.list_checks())
  end

  def create(conn, %{"check" => params}) do
    render_check_template_fn = &AppCountWeb.LetterPreviewer.render_check_template/1

    case Accounting.create_new_check(params, render_check_template_fn) do
      {:ok, base64} -> json(conn, base64)
      {:error, error} -> handle_error({:error, error}, conn)
    end
  end

  def show(conn, %{"id" => id}) do
    render_fn = &AppCountWeb.LetterPreviewer.render_check_template/1
    result = Accounting.show_check(id, render_fn)
    json(conn, result)
  end

  def update(conn, %{"id" => id, "check" => params}) do
    Accounting.update_check(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id, "cascade" => cascade}) do
    Accounting.delete_check(conn.assigns.admin, id, cascade)
    json(conn, %{})
  end
end
