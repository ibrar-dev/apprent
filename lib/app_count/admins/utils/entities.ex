defmodule AppCount.Admins.Utils.Entities do
  # an Entity is a Region which contains 1 or more Properties
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Admins.Region

  def list_entities(%AppCount.Core.ClientSchema{name: client_schema}) do
    Repo.all(
      from(
        e in Region,
        left_join: s in assoc(e, :scopings),
        on: s.region_id == e.id,
        select: %{
          id: e.id,
          name: e.name,
          property_ids: fragment("array_agg(?)", s.property_id),
          resources: e.resources
        },
        group_by: e.id,
        order_by: [
          asc: :name
        ]
      ),
      prefix: client_schema
    )
  end

  def get_entity!(%AppCount.Core.ClientSchema{name: client_schema, attrs: id}),
    do: Repo.get(Region, id, prefix: client_schema)

  def create_entity(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    %Region{}
    |> Region.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  def update_entity(region_id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    get_entity!(region_id)
    |> Region.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_entity(%AppCount.Core.ClientSchema{name: client_schema, attrs: region_id}) do
    get_entity!(%AppCount.Core.ClientSchema{name: client_schema, attrs: region_id})
    |> Repo.delete(prefix: client_schema)
  end
end
