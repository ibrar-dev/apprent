defmodule AppCount.Properties.Utils.Visits do
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Properties.Visit
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def list_visits(admin) do
    # TODO:SCHEMA remove dasmen
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      v in Visit,
      join: t in assoc(v, :tenant),
      join: p in assoc(v, :property),
      where: v.property_id in ^property_ids,
      select: %{
        id: v.id,
        description: v.description,
        inserted_at: v.inserted_at,
        admin: v.admin,
        tenant_name: fragment("? || ' ' || ?", t.first_name, t.last_name),
        property: p.name
      }
    )
    |> Repo.all()
  end

  def create_visit(params) do
    %Visit{}
    |> Visit.changeset(params)
    |> Repo.insert()
  end

  #  def update_visit(id, params) do
  #    Repo.get(Visit, id)
  #    |> Visit.changeset(params)
  #    |> Repo.update
  #  end

  def delete_visit(id) do
    Repo.get(Visit, id)
    |> Repo.delete()
  end
end
