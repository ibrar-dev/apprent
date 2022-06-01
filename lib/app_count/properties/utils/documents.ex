defmodule AppCount.Properties.Utils.Documents do
  alias AppCount.Repo
  alias AppCount.Properties.Document
  import Ecto.Query

  def list_documents(tenant_id) do
    from(
      d in Document,
      join: u in assoc(d, :document_url),
      where: d.tenant_id == ^tenant_id,
      select: map(d, [:id, :name, :type, :inserted_at, :visible]),
      select_merge: %{
        url: u.url
      }
    )
    |> Repo.all()
  end

  def create_document(params) do
    %Document{}
    |> Document.changeset(params)
    |> Repo.insert()
  end

  def update_document(id, params) do
    Repo.get(Document, id)
    |> Document.changeset(params)
    |> Repo.update()
  end

  def delete_document(id) do
    Repo.get(Document, id)
    |> Repo.delete()
  end
end
