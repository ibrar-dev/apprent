defmodule AppCount.Maintenance.Utils.Queries.Analytics do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.OpenHistory
  alias AppCount.Repo
  alias AppCount.Maintenance.Utils.Queries.AnalyticsFunctions

  # This function is meant to be of all time, not just the "dates" entered.

  def get_analytics(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: _dates},
        %AppCount.Core.ClientSchema{name: _client_schema, attrs: property_ids},
        "priority"
      ) do
    from(
      ord in Order,
      left_join: asgn in assoc(ord, :assignments),
      on: asgn.order_id == ord.id,
      join: cat in assoc(ord, :category),
      join: par in assoc(cat, :parent),
      where: ord.property_id in ^property_ids,
      where: ord.status not in ["completed", "cancelled"],
      where: not cat.third_party,
      where: par.name != "Make Ready",
      group_by: [ord.id, par.name],
      select: %{
        id: ord.id,
        status: ord.status,
        priority: ord.priority,
        assignments: jsonize(asgn, [:id, :status]),
        category: par.name
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_analytics(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: dates
        },
        %AppCount.Core.ClientSchema{name: _client_schema, attrs: property_ids},
        "completed"
      ) do
    parsed_dates = get_dates(dates)

    a_query = assignment_query("completed", List.first(parsed_dates), List.last(parsed_dates))

    from(
      o in Order,
      join: a in subquery(a_query),
      on: a.order_id == o.id,
      join: c in assoc(o, :category),
      join: p in assoc(o, :property),
      where: o.property_id in ^property_ids,
      select: %{
        id: o.id,
        completion_date: a.completed_at,
        property: %{
          id: p.id,
          name: p.name
        }
      },
      distinct: o.id,
      where: not c.third_party
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_analytics(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: dates},
        %AppCount.Core.ClientSchema{name: _client_schema, attrs: property_ids},
        "categoriesCreated"
      ) do
    parsed_dates = get_dates(dates)

    from(
      o in Order,
      join: c in assoc(o, :category),
      join: sc in assoc(c, :parent),
      where:
        o.property_id in ^property_ids and
          between(o.inserted_at, ^List.first(parsed_dates), ^List.last(parsed_dates)) and
          not c.third_party,
      select: %{
        id: o.id,
        category: sc.name,
        subcategory: c.name,
        status: o.status
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_analytics(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: dates},
        %AppCount.Core.ClientSchema{name: _client_schema, attrs: property_ids},
        "categoriesCompleted"
      ) do
    parsed_dates = get_dates(dates)
    a_query = assignment_query("completed", List.first(parsed_dates), List.last(parsed_dates))

    from(
      o in Order,
      join: a in subquery(a_query),
      on: a.order_id == o.id,
      join: c in assoc(o, :category),
      join: sc in assoc(c, :parent),
      join: tech in assoc(a, :tech),
      where: o.property_id in ^property_ids and not c.third_party,
      select: %{
        id: o.id,
        category: sc.name,
        subcategory: c.name,
        inserted_at: o.inserted_at,
        completed_at: a.completed_at,
        tech_id: tech.id,
        tech_name: tech.name,
        status: "completed"
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_analytics(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: dates},
        %AppCount.Core.ClientSchema{name: _client_schema, attrs: property_ids},
        "open"
      ) do
    parsed_dates = get_dates(dates)

    from(
      open_history in OpenHistory,
      join: property in assoc(open_history, :property),
      where:
        open_history.property_id in ^property_ids and
          between(open_history.inserted_at, ^List.first(parsed_dates), ^List.last(parsed_dates)),
      select: %{
        id: open_history.id,
        open: open_history.open,
        date: open_history.inserted_at,
        property: %{
          id: property.id,
          name: property.name
        }
      },
      order_by: :inserted_at
    )
    |> Repo.all(prefix: client_schema)
  end

  # RETURN:
  ## Currently Open work orders and total open as of 30 days ago. DONE
  ## AVG Rating all time and avg rating as of 30 days ago.
  ## Average Callback Percentage and ACP as of 30 days ago.
  ## Avg Completion Time and ACP as of 30 days ago.
  def get_analytics(_, property_ids, "info_box_open"),
    do: AnalyticsFunctions.analytics_open(property_ids)

  def get_analytics(_, property_ids, "info_box_rating"),
    do: AnalyticsFunctions.analytics_rating(property_ids)

  def get_analytics(_, property_ids, "info_box_callback"),
    do: AnalyticsFunctions.analytics_callback(property_ids)

  def get_analytics(_, property_ids, "info_box_completion_time"),
    do: AnalyticsFunctions.analytics_completion_time(property_ids)

  def get_analytics(_, property_ids, "info_box_completion_percent"),
    do: AnalyticsFunctions.analytics_completion_percent(property_ids)

  def get_analytics(_, property_ids, "analytics_completed"),
    do: AnalyticsFunctions.analytics_completed(property_ids)

  def get_analytics(_, property_ids, "info_box_reviewed_percent"),
    do: AnalyticsFunctions.work_orders_reviewed_percent(property_ids)

  defp assignment_query(status, start_date, end_date) do
    from(
      a in Assignment,
      where: a.status == ^status and between(a.completed_at, ^start_date, ^end_date),
      select: [:id, :order_id, :completed_at, :tech_id]
    )
  end

  defp get_dates(nil) do
    start_d =
      Timex.now()
      |> Timex.shift(days: -30)
      |> Timex.beginning_of_day()

    end_d =
      Timex.now()
      |> Timex.end_of_day()

    [start_d, end_d]
  end

  defp get_dates(dates) do
    start_d =
      String.split(dates, ",")
      |> List.first()
      |> Timex.parse!("{YYYY}-{0M}-{0D}")
      |> Timex.beginning_of_day()

    end_d =
      String.split(dates, ",")
      |> List.last()
      |> Timex.parse!("{YYYY}-{0M}-{0D}")
      |> Timex.end_of_day()

    [start_d, end_d]
  end
end
