defmodule AppCountWeb.API.PropertyAdminDocumentController do
  use AppCountWeb, :controller
  alias AppCount.Properties
  alias AppCount.Core.ClientSchema

  def index(conn, %{"property_ids" => property_ids}) do
    json(conn, Properties.find_documents(String.split(property_ids, ",")))
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_admin_document(ClientSchema.new(conn.assigns.admin), id)
    json(conn, %{})
  end
end
