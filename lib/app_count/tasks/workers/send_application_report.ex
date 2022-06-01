defmodule AppCount.Tasks.Workers.SendApplicationReport do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Admins
  use AppCount.Tasks.Worker, "Send application reports"
  alias AppCount.Core.ClientSchema

  @impl AppCount.Tasks.Worker
  def perform(date \\ nil) do
    from(
      a in Admins.Admin,
      where:
        fragment("'Accountant' = ANY(?)", a.roles) or fragment("'Regional' = ANY(?)", a.roles),
      select: a,
      distinct: a.id
    )
    |> Repo.all()
    |> Enum.each(fn x -> do_send_application_report(x, date) end)
  end

  def do_send_application_report(admin, date) do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))
    start_date = Timex.beginning_of_day(date || AppCount.current_time())
    end_date = Timex.end_of_day(start_date)

    apps =
      from(
        a in AppCount.RentApply.RentApplication,
        join: p in assoc(a, :persons),
        join: pay in assoc(a, :payments),
        join: prop in assoc(a, :property),
        where: between(a.inserted_at, ^start_date, ^end_date),
        where: a.property_id in ^property_ids,
        where: p.status == "Lease Holder",
        select: %{
          id: a.id,
          payment_amount: sum(pay.amount),
          people_amount: count(p.id),
          people: jsonize(p, [:id, :full_name]),
          inserted_at: a.inserted_at,
          property: prop.name,
          property_id: prop.id
        },
        group_by: [a.id, prop.id]
      )

    properties =
      from(
        p in AppCount.Properties.Property,
        join: apps in subquery(apps),
        on: apps.property_id == p.id,
        left_join: i in assoc(p, :icon_url),
        where: p.id in ^property_ids,
        select: %{
          id: p.id,
          property: p.name,
          icon: i.url,
          apps: jsonize(apps, [:id, :payment_amount, :people_amount, :inserted_at, :people]),
          sum: sum(apps.payment_amount),
          total_apps: count(apps.id)
        },
        group_by: [p.id, i.url],
        order_by: [asc: :name]
      )
      |> Repo.all()

    cond do
      length(properties) > 0 ->
        AppCountCom.Applications.send_daily_applications(properties, admin)

      true ->
        nil
    end
  end
end
