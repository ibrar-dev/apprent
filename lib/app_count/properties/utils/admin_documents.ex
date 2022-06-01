defmodule AppCount.Properties.Utils.AdminDocuments do
  alias AppCount.Repo
  alias AppCount.Properties.AdminDocument
  alias AppCount.Properties.PropertyAdminDocument
  alias AppCount.Core.ClientSchema

  def create_admin_document(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    %AdminDocument{}
    |> AdminDocument.changeset(params)
    |> Repo.insert(prefix: client_schema)
    |> case do
      {:ok, admin_document} ->
        Enum.each(
          params["property_ids"],
          fn p ->
            %PropertyAdminDocument{}
            |> PropertyAdminDocument.changeset(%{
              property_id: p,
              admin_document_id: admin_document.id
            })
            |> Repo.insert(prefix: client_schema)
          end
        )

        {:ok, admin_document}

      e ->
        e
    end
  end

  def update_admin_document(id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    Repo.get(AdminDocument, id)
    |> AdminDocument.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_admin_document(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, id) do
    Repo.get(AdminDocument, id, prefix: client_schema)
    |> AppCount.Admins.Utils.Actions.admin_delete(ClientSchema.new(client_schema, admin))
  end
end
