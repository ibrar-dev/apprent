defmodule AppCount.Prospects.Utils.Prospects do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Prospects.Prospect
  alias AppCount.Prospects.Memo
  alias AppCount.Core.ClientSchema

  def list_prospects(admin) do
    memos_query =
      from(
        m in Memo,
        join: p in assoc(m, :prospect),
        select: %{
          id: m.id,
          admin: m.admin,
          prospect_id: m.prospect_id,
          notes: m.notes,
          contact_date: m.inserted_at
        },
        order_by: [
          desc: :inserted_at
        ]
      )

    from(
      p in Prospect,
      left_join: prop in assoc(p, :property),
      left_join: a in assoc(p, :admin),
      left_join: t in assoc(p, :traffic_source),
      left_join: s in assoc(p, :showings),
      left_join: m in subquery(memos_query),
      on: m.prospect_id == p.id,
      select:
        map(p, [
          :id,
          :name,
          :email,
          :contact_date,
          :address,
          :move_in,
          :phone,
          :contact_type,
          :contact_result,
          :notes
        ]),
      select_merge: %{
        agent: map(a, [:id, :name]),
        property: map(prop, [:id, :name]),
        traffic_source: map(t, [:id, :name]),
        showings: jsonize(s, [:id, :date, :property_id]),
        memos: jsonize(m, [:id, :contact_date, :notes, :admin])
      },
      where: p.property_id in ^Admins.property_ids_for(ClientSchema.new("dasmen", admin)),
      group_by: [p.id, t.id, a.id, prop.id]
    )
    |> Repo.all()
  end

  def list_prospects_for(admin) do
    from(p in Prospect, where: p.admin_id == ^admin.id)
    |> Repo.all()
  end

  def create_prospect(params) do
    %Prospect{}
    |> Prospect.changeset(params)
    |> Repo.insert()
  end

  def update_prospect(id, params) do
    Repo.get(Prospect, id)
    |> Prospect.changeset(params)
    |> Repo.update()
  end

  def delete_prospect(id) do
    Repo.get(Prospect, id)
    |> Repo.delete()
  end
end
