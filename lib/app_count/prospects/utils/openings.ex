defmodule AppCount.Prospects.Utils.Openings do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Prospects.Closure
  alias AppCount.Prospects.Opening
  alias AppCount.Prospects.Showing
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  def list_available(property_id) do
    closure_query =
      from(
        c in Closure,
        select: map(c, [:id, :property_id, :date, :start_time, :end_time, :reason])
      )

    showings_query =
      from(
        s in Showing,
        where: is_nil(s.cancellation),
        select: map(s, [:id, :date, :start_time, :end_time, :property_id])
      )

    from(
      o in Opening,
      join: p in assoc(o, :property),
      left_join: s in subquery(showings_query),
      on: s.property_id == o.property_id,
      left_join: c in subquery(closure_query),
      on: c.property_id == o.property_id,
      select: %{
        openings: jsonize(o, [:id, :wday, :showing_slots, :start_time, :end_time]),
        showings: jsonize(s, [:id, :date, :start_time, :end_time]),
        closures: jsonize(c, [:id, :date, :start_time, :end_time, :reason])
      },
      where: o.property_id == ^property_id
    )
    |> Repo.one()
  end

  def list_openings(%ClientSchema{name: client_schema, attrs: admin}) do
    from(
      o in Opening,
      select: map(o, [:id, :wday, :showing_slots, :start_time, :end_time, :property_id]),
      where: o.property_id in ^Admins.property_ids_for(ClientSchema.new(client_schema, admin))
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_opening(%ClientSchema{name: client_schema, attrs: params}) do
    %Opening{}
    |> Opening.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  def update_opening(%ClientSchema{name: client_schema, attrs: id}, params) do
    Repo.get(Opening, id)
    |> Opening.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_opening(%ClientSchema{name: client_schema, attrs: id}) do
    Repo.get(Opening, id)
    |> Repo.delete(prefix: client_schema)
  end
end
