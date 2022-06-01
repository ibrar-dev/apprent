defmodule AppCount.Properties.Utils.PropertyAdminDocuments do
  alias AppCount.Repo
  alias AppCount.Properties.PropertyAdminDocument
  import Ecto.Query

  def create_document_property(params) do
    %PropertyAdminDocument{}
    |> PropertyAdminDocument.changeset(params)
    |> Repo.insert()
  end

  def find_documents(property_ids) do
    from(
      pad in PropertyAdminDocument,
      join: p in assoc(pad, :property),
      join: ad in assoc(pad, :admin_document),
      join: u in assoc(ad, :document_url),
      where: p.id in ^property_ids,
      select: %{
        id: pad.id,
        property_id: p.id,
        property_name: p.name,
        document_id: ad.id,
        name: ad.name,
        creator: ad.creator,
        type: ad.type
      },
      select_merge: %{url: u.url},
      distinct: ad.id
    )
    |> Repo.all()
  end
end
