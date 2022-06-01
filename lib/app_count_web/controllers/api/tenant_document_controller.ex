defmodule AppCountWeb.API.TenantDocumentController do
  use AppCountWeb, :controller
  alias AppCount.Properties

  authorize(["Admin"])

  def index(conn, %{"tenant_id" => tenant_id}) do
    json(conn, Properties.list_documents(tenant_id))
  end

  def create(conn, %{"document" => params}) do
    Properties.create_document(params)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "document" => params}) do
    Properties.update_document(id, params)
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_document(id)
    |> handle_error(conn)
  end
end
