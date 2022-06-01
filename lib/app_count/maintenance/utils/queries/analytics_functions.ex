defmodule AppCount.Maintenance.Utils.Queries.AnalyticsFunctions do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.OpenHistory

  use AppCount.Decimal
  # RETURN:
  ## Currently Open work orders and total open as of 30 days ago.
  ## AVG Rating all time and avg rating as of 30 days ago.
  ## Average Callback Percentage and ACP as of 30 days ago.
  ## Avg Completion Time and ACP as of 30 days ago.

  ## indicator: false == BAD, true == GOOD
  def analytics_open(property_ids) do
    currently_open = get_open_work_orders(property_ids, :current)
    comparison = get_open_work_orders(property_ids, :compare)
    # currently_open = get_open_work_orders(property_ids, "2020-06-01,#{today}")
    # comparison = get_open_work_orders(property_ids, "2020-06-01,#{compare}")
    %{
      current: currently_open,
      comparison: comparison,
      indicator: currently_open <= comparison
    }
  end

  def analytics_completed(property_ids) do
    current = get_completed_orders(property_ids, dates(:compare))
    compare = get_completed_orders(property_ids, dates(:prior))

    %{
      current: current,
      comparison: compare,
      indicator: current >= compare
    }
  end

  def analytics_rating(%AppCount.Core.ClientSchema{} = wrapped_property_ids) do
    current =
      get_avg_rating(
        wrapped_property_ids,
        dates(:compare)
      )

    compare =
      get_avg_rating(
        wrapped_property_ids,
        dates(:prior)
      )

    %{
      current: current,
      comparison: compare,
      indicator: current >= compare
    }
  end

  def analytics_callback(property_ids) do
    start_date =
      AppCount.current_time()
      |> Timex.shift(days: -60)
      |> Timex.beginning_of_day()

    end_date =
      AppCount.current_time()
      |> Timex.shift(days: -31)
      |> Timex.end_of_day()

    current = callbacks_percentage(property_ids, [start_date, end_date])
    compare = callbacks_percentage(property_ids, dates(:compare))

    %{
      current: current,
      comparison: compare,
      indicator: current <= compare
    }
  end

  def analytics_completion_time(property_ids) do
    current = completion_time(property_ids, dates(:compare))
    compare = completion_time(property_ids, dates(:prior))

    %{
      current: current,
      comparison: compare,
      indicator: current <= compare
    }
  end

  def analytics_completion_percent(property_ids) do
    current = completion_percent(property_ids, dates(:current))
    compare = completion_percent(property_ids, dates(:prior))

    %{
      current: current,
      comparison: compare,
      indicator: current >= compare
    }
  end

  def work_orders_reviewed_percent(property_ids) do
    current = reviewed_percent(property_ids, dates(:current))
    compare = reviewed_percent(property_ids, dates(:prior))

    %{
      current: current,
      comparison: compare,
      indicator: current >= compare
    }
  end

  def reviewed_percent(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property_ids},
        dates
      ) do
    completed =
      from(
        a in Assignment,
        join: o in assoc(a, :order),
        where:
          not is_nil(a.completed_at) and o.property_id in ^property_ids and
            between(a.completed_at, ^List.first(dates), ^List.last(dates)),
        select: count(o.id)
      )
      |> Repo.one(prefix: client_schema)

    reviewed =
      from(
        a in Assignment,
        join: o in assoc(a, :order),
        where:
          not is_nil(a.completed_at) and
            o.property_id in ^property_ids and
            between(a.completed_at, ^List.first(dates), ^List.last(dates)) and
            not is_nil(a.rating),
        select: count(o.id)
      )
      |> Repo.one(prefix: client_schema)

    calculate_percentage(reviewed, completed)
  end

  def completion_percent(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property_ids},
        dates
      ) do
    # get total of created, total of completed within the entered dates
    # return percentage of completed, so calculate_percentage(completed, created)
    created =
      from(
        o in Order,
        where:
          o.property_id in ^property_ids and
            between(o.inserted_at, ^List.first(dates), ^List.last(dates)),
        select: count(o.id)
      )
      |> Repo.one(prefix: client_schema)

    completed =
      from(
        a in Assignment,
        join: o in assoc(a, :order),
        where:
          not is_nil(a.completed_at) and o.property_id in ^property_ids and
            between(a.completed_at, ^List.first(dates), ^List.last(dates)),
        select: count(o.id)
      )
      |> Repo.one(prefix: client_schema)

    calculate_percentage(completed, created)
  end

  # untested
  # see also:  AppCount.Properties.PropertyRepo.completion_time(property_id, %DateTimeRange{})
  #
  def completion_time(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property_ids},
        dates
      )
      when is_list(property_ids) do
    from(
      a in Assignment,
      join: o in assoc(a, :order),
      where:
        not is_nil(a.completed_at) and o.property_id in ^property_ids and
          between(a.completed_at, ^List.first(dates), ^List.last(dates)),
      select:
        fragment(
          "avg(EXTRACT(EPOCH FROM ?) - EXTRACT(EPOCH FROM ?))",
          a.completed_at,
          o.inserted_at
        )
    )
    |> Repo.one(prefix: client_schema)
  end

  def callbacks_percentage(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property_ids},
        dates
      ) do
    callbacks =
      from(
        a in Assignment,
        join: o in assoc(a, :order),
        where:
          a.status == "callback" and o.property_id in ^property_ids and
            between(a.completed_at, ^List.first(dates), ^List.last(dates)),
        select: count(a.id)
      )
      |> Repo.one(prefix: client_schema)

    completed =
      from(
        a in Assignment,
        join: o in assoc(a, :order),
        where:
          not is_nil(a.completed_at) and o.property_id in ^property_ids and
            between(a.completed_at, ^List.first(dates), ^List.last(dates)),
        select: count(a.id)
      )
      |> Repo.one(prefix: client_schema)

    calculate_percentage(callbacks, completed)
  end

  def get_avg_rating(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: property_ids
        },
        dates
      ) do
    from(
      a in Assignment,
      join: o in assoc(a, :order),
      where:
        not is_nil(a.rating) and o.property_id in ^property_ids and
          between(a.completed_at, ^List.first(dates), ^List.last(dates)),
      select: avg(a.rating)
    )
    |> Repo.one(prefix: client_schema)
  end

  # see also:
  # AppCount.Properties.PropertyRepo.completed_orders(property_id, %DateTimeRange{})
  #
  def get_completed_orders(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property_ids},
        dates
      ) do
    from(
      a in Assignment,
      join: o in assoc(a, :order),
      where:
        not is_nil(a.completed_at) and o.property_id in ^property_ids and
          between(a.completed_at, ^List.first(dates), ^List.last(dates)),
      select: count(a.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def get_open_work_orders(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property_ids},
        :compare
      ) do
    start_date =
      AppCount.current_time()
      |> Timex.shift(days: -30)
      |> Timex.beginning_of_day()

    end_date =
      start_date
      |> Timex.end_of_day()

    from(
      o in OpenHistory,
      where: o.property_id in ^property_ids and between(o.inserted_at, ^start_date, ^end_date),
      select: sum(o.open)
    )
    |> Repo.one(prefix: client_schema)
  end

  def get_open_work_orders(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property_ids},
        :current
      ) do
    start_date =
      Timex.parse!("2020-06-01", "{YYYY}-{0M}-{0D}")
      |> Timex.beginning_of_day()

    maintenance_orders =
      from(
        o in Order,
        join: c in assoc(o, :category),
        join: pc in assoc(c, :parent),
        where: o.status in ["unassigned", "assigned"] and o.property_id in ^property_ids,
        where: o.inserted_at >= ^start_date,
        where: pc.name != "Make Ready",
        select: count(o.id)
      )
      |> Repo.one(prefix: client_schema)

    vendor_orders =
      from(
        o in AppCount.Vendors.Order,
        join: u in assoc(o, :unit),
        where: o.status == "Open" and u.property_id in ^property_ids,
        select: count(o.id)
      )
      |> Repo.one(prefix: client_schema)

    maintenance_orders + vendor_orders
  end

  def calculate_percentage(_low, 0), do: 100
  def calculate_percentage(low, high), do: low / high * 100

  def dates(:current) do
    start_date =
      Timex.parse!("2018-04-01", "{YYYY}-{0M}-{0D}")
      |> Timex.beginning_of_day()

    end_date =
      AppCount.current_time()
      |> Timex.end_of_day()

    [start_date, end_date]
  end

  def dates(:compare) do
    start_date =
      AppCount.current_time()
      |> Timex.shift(days: -30)
      |> Timex.beginning_of_day()

    end_date =
      AppCount.current_time()
      |> Timex.end_of_day()

    [start_date, end_date]
  end

  def dates(:prior) do
    start_date =
      AppCount.current_time()
      |> Timex.shift(days: -60)
      |> Timex.beginning_of_day()

    end_date =
      start_date
      |> Timex.shift(days: 31)
      |> Timex.end_of_day()

    [start_date, end_date]
  end
end
