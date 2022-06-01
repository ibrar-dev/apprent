defmodule AppCount.Maintenance.Utils.Queries.Reports do
  import AppCount.EctoExtensions
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Maintenance
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  def daily_maintenance_snapshot(admin, property_id) when is_integer(property_id),
    do: daily_maintenance_snapshot(admin, [property_id])

  def daily_maintenance_snapshot(admin, property_id) do
    today =
      AppCount.current_date()
      |> Timex.format!("%Y-%m-%d", :strftime)

    %{unassigned: unassigned, assigned: assigned, completed: _completed} =
      Maintenance.list_orders_new(admin, "2020-06-01,#{today}", property_id)

    %{rating: rating, completion_time: completion_time} = tech_stats(admin, property_id)
    #
    violations =
      (unassigned ++ assigned)
      |> Enum.filter(&(&1.priority == 3))
      |> length

    #
    total_open = length(unassigned) + length(assigned)

    %{
      open_violations: violations,
      total_open: total_open,
      mtd_callbacks: get_mtd_callbacks(property_id),
      rating: rating,
      avg_completion_time: completion_time
    }
  end

  defp get_mtd_callbacks(%AppCount.Core.ClientSchema{name: client_schema, attrs: property_id})
       when is_integer(property_id),
       do:
         get_mtd_callbacks(%AppCount.Core.ClientSchema{name: client_schema, attrs: [property_id]})

  defp get_mtd_callbacks(%AppCount.Core.ClientSchema{name: client_schema, attrs: property_id}) do
    start_time =
      AppCount.current_time()
      |> Timex.beginning_of_month()

    end_time =
      AppCount.current_time()
      |> Timex.end_of_day()

    from(
      a in Maintenance.Assignment,
      join: o in assoc(a, :order),
      where: o.property_id in ^property_id,
      where: a.status == "callback" and between(a.completed_at, ^start_time, ^end_time),
      distinct: a.order_id,
      select: count(a.id),
      group_by: [a.order_id]
    )
    |> Repo.one(prefix: client_schema)
  end

  defp tech_stats(admin, property_id) when is_integer(property_id),
    do: tech_stats(admin, [property_id])

  defp tech_stats(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, property_id) do
    stats = Maintenance.Utils.Reports.tech_stats_query()
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      t in Maintenance.Tech,
      join: j in assoc(t, :jobs),
      join: s in subquery(stats),
      on: t.id == s.tech_id,
      where: j.property_id in ^property_id and j.property_id in ^property_ids,
      select: %{
        rating: avg(s.rating),
        completion_time: avg(s.completion_time)
      }
    )
    |> Repo.one(prefix: client_schema)
  end
end

# Vacant Ready Units
# Vacant Not Ready Units
# Average W/O Completion Time
# Average Tech Rating
