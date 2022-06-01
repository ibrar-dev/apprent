defmodule AppCount.Maintenance.Utils.PaidTimes do
  import Ecto.Query
  alias AppCount.Maintenance.PaidTime
  alias AppCount.Maintenance.Tech
  alias AppCount.Repo
  alias AppCount.Admins
  import AppCount.EctoExtensions
  alias AppCount.Core.ClientSchema

  def list_paid_times(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      }) do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))
    #    sub_query = from(
    #      p in PaidTime,
    #      select: [:id, :hours, :approved, :reason]
    #    )
    from(
      t in Tech,
      left_join: p in assoc(t, :paid_times),
      left_join: j in assoc(t, :jobs),
      select: %{
        id: t.id,
        name: t.name,
        email: t.email,
        phone: t.phone_number,
        type: t.type,
        description: t.description,
        accrued: sum(p.hours),
        accruals: jsonize(p, [:id, :hours, :date, :approved, :reason])
      },
      where: j.property_id in ^property_ids,
      group_by: [t.id],
      order_by: [
        asc: t.name
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_paid_time(params) do
    %PaidTime{}
    |> PaidTime.changeset(params)
    |> Repo.insert!()
  end

  def update_paid_time(id, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    Repo.get(PaidTime, id, prefix: client_schema)
    |> PaidTime.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_paid_time(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    Repo.get(PaidTime, id, prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end
end
