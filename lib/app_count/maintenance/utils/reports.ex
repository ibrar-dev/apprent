defmodule AppCount.Maintenance.Utils.Reports do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Card
  alias AppCount.Maintenance.CardItem
  alias AppCount.Properties.Property
  alias AppCount.Maintenance.Utils.Orders
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  def property_report(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      }) do
    property_ids = Admins.property_ids_for(ClientSchema.new(client_schema, admin))

    from(
      a in Assignment,
      join: o in assoc(a, :order),
      join: u in assoc(o, :unit),
      join: p in assoc(u, :property),
      join: c in assoc(o, :category),
      select: %{
        id: p.id,
        name: p.name,
        materials: array(a.materials),
        callbacks: count_by(a.status, "callback"),
        rating_count: count(a.rating),
        ratings_1: count_by(a.rating, "1"),
        ratings_2: count_by(a.rating, "2"),
        ratings_3: count_by(a.rating, "3"),
        ratings_4: count_by(a.rating, "4"),
        ratings_5: count_by(a.rating, "5"),
        rating: avg(a.rating),
        completed: count_by(a.status, "completed"),
        orders: count(o.id, :distinct)
      },
      group_by: p.id,
      #      where: p.id in ^property_ids
      where: p.id in ^property_ids and not c.third_party
    )
    |> Repo.all(prefix: client_schema)
  end

  def unit_report(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      }) do
    property_ids = Admins.property_ids_for(ClientSchema.new(client_schema, admin))

    from(
      a in Assignment,
      join: o in assoc(a, :order),
      join: u in assoc(o, :unit),
      join: p in assoc(u, :property),
      join: c in assoc(o, :category),
      select: %{
        id: u.id,
        property_id: p.id,
        number: u.number,
        materials: array(a.materials),
        callbacks: count_by(a.status, "callback"),
        completed: count_by(a.status, "completed"),
        orders: count(o.id, :distinct)
      },
      group_by: [u.id, p.id],
      where: p.id in ^property_ids and not c.third_party
    )
    |> Repo.all(prefix: client_schema)
  end

  def month_stats_query do
    start_of_month =
      AppCount.current_time()
      |> Timex.beginning_of_month()

    end_of_month =
      AppCount.current_time()
      |> Timex.end_of_month()

    from(
      a in Assignment,
      where:
        a.status in ["completed", "callback"] and a.completed_at >= ^start_of_month and
          a.completed_at <= ^end_of_month,
      select: %{
        rating: avg(a.rating),
        completion_time:
          fragment(
            "avg(EXTRACT(EPOCH FROM(? - ?)))",
            a.completed_at,
            a.confirmed_at
          ),
        tech_id: a.tech_id,
        id: a.tech_id
      },
      group_by: a.tech_id
    )
  end

  def tech_stats_query do
    from(
      a in Assignment,
      where: a.status in ["completed", "callback"],
      select: %{
        id: a.tech_id,
        tech_id: a.tech_id,
        rating: avg(a.rating),
        completion_time:
          fragment(
            "avg(EXTRACT(EPOCH FROM(? - ?)))",
            a.completed_at,
            a.confirmed_at
          ),
        callbacks: count_by(a.status, "callback"),
        completed: count_by(a.status, "completed")
      },
      group_by: a.tech_id
    )
  end

  def tech_stats_query(start_date) do
    from(
      a in Assignment,
      where: a.status in ["completed", "callback"] and a.completed_at > ^start_date,
      select: %{
        tech_id: a.tech_id,
        callbacks: count_by(a.status, "callback"),
        completed: count_by(a.status, "completed")
      },
      group_by: a.tech_id
    )
  end

  ## Pass In Tech ID and Date and get reading for that tech and date
  def tech_stats_query(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: tech_id
        },
        date
      ) do
    start_of_day = Timex.beginning_of_day(date)
    end_of_day = Timex.end_of_day(date)
    tech = Repo.get(Tech, tech_id)

    orders_completed =
      from(
        a in Assignment,
        where:
          a.status in ["completed", "callback"] and a.completed_at > ^start_of_day and
            a.completed_at < ^end_of_day and a.tech_id == ^tech_id,
        select: a.id
      )
      |> Repo.all(prefix: client_schema)
      |> Kernel.length()

    %{
      tech: tech.name,
      id: tech.id,
      orders: orders_completed
    }
  end

  ## Pass In Tech ID and Start Date(furthest date) and End Date(closest date) and get reading for that tech and time period
  def tech_stats_query(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: tech_id
        },
        start_date,
        end_date
      ) do
    start_of_day = Timex.beginning_of_day(start_date)
    end_of_day = Timex.end_of_day(end_date)
    tech = Repo.get(Tech, tech_id)

    orders_completed =
      from(
        a in Assignment,
        where:
          a.status in ["completed", "callback"] and a.completed_at > ^start_of_day and
            a.completed_at < ^end_of_day and a.tech_id == ^tech_id,
        select: a.id
      )
      |> Repo.all(prefix: client_schema)
      |> Kernel.length()

    %{
      tech: tech.name,
      id: tech.id,
      orders: orders_completed
    }
  end

  def property_stats_query_by_admin_six_months(admin_id) do
    admin = Repo.get(AppCount.Admins.Admin, admin_id)
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))
    Enum.map(property_ids, fn x -> property_stats_query_by_admin(x) end)
  end

  def property_stats_query_by_admin_six_months(
        %ClientSchema{name: client_schema, attrs: _admin_id},
        property_id
      ) do
    [property_stats_query_by_admin(ClientSchema.new(client_schema, property_id))]
  end

  def property_stats_query_by_admin_dates(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        start_d,
        end_d
      ) do
    admin = Repo.get(AppCount.Admins.Admin, admin.id, prefix: client_schema)
    property_ids = Admins.property_ids_for(ClientSchema.new(client_schema, admin))

    Enum.map(property_ids, fn x ->
      property_stats_query(ClientSchema.new(client_schema, x), start_d, end_d)
    end)
  end

  def property_stats_query_by_admin(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_id
      }) do
    property =
      from(
        p in Property,
        left_join: i in assoc(p, :icon_url),
        where: p.id == ^property_id,
        select: %{
          id: p.id,
          name: p.name,
          primary_color: p.primary_color,
          icon: i.url
        },
        limit: 1
      )
      |> Repo.one(prefix: client_schema)

    stats =
      Enum.map(
        0..5,
        fn x ->
          date = Timex.shift(AppCount.current_time(), months: -x)
          beginning_of_month = Timex.beginning_of_month(date)
          end_of_month = Timex.end_of_month(date)

          property_stats_query(
            ClientSchema.new(client_schema, property_id),
            beginning_of_month,
            end_of_month
          )
        end
      )

    %{property: property, stats: stats}
  end

  defp property_stats_query(
         %AppCount.Core.ClientSchema{
           name: client_schema,
           attrs: property_id
         },
         start_date,
         end_date
       ) do
    assignment_query =
      from(
        a in Assignment,
        where: a.status == "completed",
        select: %{
          order_id: a.order_id,
          completed_at: a.completed_at,
          status: a.status,
          rating: a.rating
        }
      )

    # This is just completed orders
    orders =
      from(
        o in Order,
        join: p in assoc(o, :property),
        join: c in assoc(o, :category),
        join: a in subquery(assignment_query),
        on: a.order_id == o.id,
        select: %{
          property_name: p.name,
          completion_time:
            fragment(
              "avg(EXTRACT(EPOCH FROM ?) - EXTRACT(EPOCH FROM ?))",
              a.completed_at,
              o.inserted_at
            ),
          total_completed: count(o.id),
          avg_rating: avg(a.rating),
          total_rating: count(a.rating)
        },
        where:
          o.inserted_at > ^start_date and o.inserted_at < ^end_date and
            o.property_id == ^property_id and not c.third_party,
        group_by: p.id
      )
      |> Repo.one(prefix: client_schema)

    # All orders submitted
    submitted_orders =
      from(
        o in Order,
        join: p in assoc(o, :property),
        join: c in assoc(o, :category),
        where:
          o.inserted_at > ^start_date and o.inserted_at < ^end_date and
            o.property_id == ^property_id and not c.third_party,
        select: count(o.id)
      )
      |> Repo.one(prefix: client_schema)

    tp_orders =
      from(
        o in Order,
        join: p in assoc(o, :property),
        join: c in assoc(o, :category),
        join: a in subquery(assignment_query),
        on: a.order_id == o.id,
        select: %{
          completion_time:
            fragment(
              "avg(EXTRACT(EPOCH FROM ?) - EXTRACT(EPOCH FROM ?))",
              a.completed_at,
              o.inserted_at
            ),
          total_completed: count(o.id),
          avg_rating: avg(a.rating)
        },
        where:
          o.inserted_at > ^start_date and o.inserted_at < ^end_date and
            o.property_id == ^property_id and c.third_party,
        group_by: p.id
      )
      |> Repo.one(prefix: client_schema)

    ci_query =
      from(
        ci in CardItem,
        select: %{
          id: ci.id,
          card_id: ci.card_id,
          completed: ci.completed
        },
        where:
          ci.name == "Final Inspection" and not is_nil(ci.completed) and
            ci.completed <= ^start_date
      )

    vacants =
      from(
        c in Card,
        left_join: ci in subquery(ci_query),
        on: ci.card_id == c.id,
        join: u in assoc(c, :unit),
        join: p in assoc(u, :property),
        select: %{
          vacants: count(p.id)
        },
        where: p.id == ^property_id,
        where: c.inserted_at <= ^Timex.shift(end_date, days: -5),
        where: is_nil(ci.id),
        group_by: p.id
      )
      |> Repo.one(prefix: client_schema)

    ci_completed_query =
      from(
        ci in CardItem,
        select: %{
          id: ci.id,
          card_id: ci.card_id,
          completed: ci.completed
        },
        where: ci.name == "Final Inspection" and not is_nil(ci.completed),
        where: ci.completed >= ^start_date and ci.completed <= ^end_date
      )

    make_readies =
      from(
        c in Card,
        join: ci in subquery(ci_completed_query),
        on: ci.card_id == c.id,
        join: u in assoc(c, :unit),
        join: p in assoc(u, :property),
        select: %{
          completed: count(ci)
        },
        where: p.id == ^property_id,
        group_by: p.id
      )
      |> Repo.one(prefix: client_schema)

    %{
      average_completion_time: orders[:completion_time],
      tp_orders: tp_orders,
      name: orders[:property_name],
      total_completed: orders[:total_completed],
      total_submitted: submitted_orders,
      vacants: vacants[:vacants],
      make_readies: make_readies[:completed],
      month: start_date,
      avg_rating: orders[:avg_rating],
      total_rating: orders[:total_rating]
    }
  end

  def send_daily_report(notes, admins, admin) do
    info = Orders.info_for_daily_report(admin)

    Enum.each(
      admins,
      fn a ->
        AppCount.Repo.get(AppCount.Admins.Admin, a)
        |> AppCountCom.WorkOrders.ms_daily_report(notes, info, admin)
      end
    )
  end

  def admin_completed(admin, date) do
    start_date = Timex.beginning_of_day(date)
    end_date = Timex.end_of_day(date)
    admin_completed(admin, start_date, end_date)
  end

  def admin_completed(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        start_date,
        end_date
      ) do
    start_date = Timex.beginning_of_day(start_date)
    end_date = Timex.end_of_day(end_date)
    property_ids = Admins.property_ids_for(ClientSchema.new(client_schema, admin))

    assignment_query =
      from(
        a in AppCount.Maintenance.Assignment,
        where: a.status == "completed" and between(a.completed_at, ^start_date, ^end_date),
        select: %{
          id: a.id,
          order_id: a.order_id,
          completed_at: a.completed_at
        }
      )

    from(
      o in AppCount.Maintenance.Order,
      join: a in subquery(assignment_query),
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

  def admin_categories(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        date
      ) do
    admin_categories(
      %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      },
      date,
      date
    )
  end

  def admin_categories(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        start_date,
        end_date
      ) do
    start_day = Timex.beginning_of_day(start_date)
    end_day = Timex.end_of_day(end_date)
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      o in AppCount.Maintenance.Order,
      join: c in assoc(o, :category),
      join: sc in assoc(c, :parent),
      where:
        o.property_id in ^property_ids and between(o.inserted_at, ^start_day, ^end_day) and
          not c.third_party,
      select: %{
        id: o.id,
        category: sc.name,
        subcategory: c.name
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def admin_categories_completed(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        date
      ) do
    admin_categories_completed(
      %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      },
      date,
      date
    )
  end

  def admin_categories_completed(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        start_date,
        end_date
      ) do
    start_day = Timex.beginning_of_day(start_date)
    end_day = Timex.end_of_day(end_date)
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    a_query =
      from(
        a in AppCount.Maintenance.Assignment,
        where: a.status == "completed" and between(a.completed_at, ^start_day, ^end_day),
        select: %{
          id: a.id,
          order_id: a.order_id,
          completed_at: a.completed_at
        }
      )

    from(
      o in AppCount.Maintenance.Order,
      join: a in subquery(a_query),
      on: a.order_id == o.id,
      join: c in assoc(o, :category),
      join: sc in assoc(c, :parent),
      where: o.property_id in ^property_ids and not c.third_party,
      select: %{
        id: o.id,
        category: sc.name,
        subcategory: c.name,
        inserted_at: o.inserted_at,
        completed_at: a.completed_at
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def tech_report(%ClientSchema{
        name: client_schema,
        attrs: %{
          "techs" => tech_ids,
          "startDate" => start_date,
          "endDate" => end_date,
          "selectedProperties" => property_ids
        }
      }) do
    start_day = Timex.parse!(start_date, "{YYYY}-{0M}-{D}")
    end_day = Timex.parse!(end_date, "{YYYY}-{0M}-{D}")
    tech_report(ClientSchema.new(client_schema, tech_ids), start_day, end_day, property_ids)
  end

  def tech_report(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: tech_ids
        },
        start_date,
        end_date,
        property_ids
      ) do
    start_day = Timex.beginning_of_day(start_date)
    end_day = Timex.end_of_day(end_date)

    punches =
      from(
        ci in CardItem,
        join: c in assoc(ci, :card),
        join: u in assoc(c, :unit),
        where: ci.name == "Punch",
        where:
          not is_nil(ci.completed) and ci.completed >= ^start_date and ci.completed <= ^end_date and
            u.property_id in ^property_ids,
        select: %{
          id: ci.id,
          unit: u.number,
          tech_id: ci.tech_id,
          completed: ci.completed
        }
      )

    assignments =
      from(
        a in AppCount.Maintenance.Assignment,
        join: o in assoc(a, :order),
        select: %{
          id: a.id,
          inserted_at: a.inserted_at,
          status: a.status,
          completed_at: a.completed_at,
          order_id: a.order_id,
          tech_id: a.tech_id,
          rating: a.rating
        },
        where:
          o.property_id in ^property_ids and
            (between(a.inserted_at, ^start_day, ^end_day) or
               between(a.completed_at, ^start_day, ^end_day)),
        order_by: :inserted_at
      )

    from(
      t in Tech,
      left_join: a in subquery(assignments),
      on: a.tech_id == t.id,
      left_join: p in subquery(punches),
      on: p.tech_id == t.id,
      join: j in assoc(t, :jobs),
      select: %{
        id: t.id,
        name: t.name,
        image: t.image,
        assignments: jsonize(a, [:id, :status, :inserted_at, :completed_at, :order_id, :rating]),
        punches: jsonize(p, [:id, :unit, :completed]),
        properties: array(j.property_id)
      },
      where: t.id in ^tech_ids and j.property_id in ^property_ids,
      group_by: [t.id]
    )
    |> Repo.all(prefix: client_schema)
  end

  def make_ready_report(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        start_date,
        end_date
      ) do
    punch_query =
      from(
        c in CardItem,
        left_join: t in assoc(c, :tech),
        where: c.name == "Punch",
        select: %{
          id: c.card_id,
          tech: t.name
        }
      )

    completed_query =
      from(
        c in CardItem,
        where: not is_nil(c.completed) and c.name == "Final Inspection",
        where: c.completed >= ^start_date and c.completed <= ^end_date,
        select: %{
          id: c.id,
          completed: c.completed,
          completed_by: c.completed_by,
          notes: c.notes,
          card_id: c.card_id
        }
      )

    card_query =
      from(
        c in Card,
        join: ci in subquery(completed_query),
        on: ci.card_id == c.id,
        left_join: t in subquery(punch_query),
        on: c.id == t.id,
        join: l in assoc(c, :lease),
        join: u in assoc(l, :unit),
        select: %{
          id: c.id,
          inserted_at: c.inserted_at,
          completion: c.completion,
          unit: u.number,
          admin: c.admin,
          completed_at: ci.completed,
          property_id: u.property_id,
          move_out_date: l.actual_move_out,
          punch_tech: t.tech
        }
      )

    from(
      p in Property,
      left_join: c in subquery(card_query),
      on: c.property_id == p.id,
      left_join: i in assoc(p, :icon_url),
      where: p.id in ^admin.property_ids,
      select: %{
        id: p.id,
        name: p.name,
        icon: i.url,
        completion_time:
          fragment(
            "avg(EXTRACT(EPOCH FROM ?) - EXTRACT(EPOCH FROM ?))",
            c.completed_at,
            c.inserted_at
          ),
        units:
          jsonize(
            c,
            [
              :id,
              :inserted_at,
              :completion,
              :unit,
              :admin,
              :completed_at,
              :move_out_date,
              :punch_tech
            ]
          )
      },
      group_by: [p.id, i.url],
      order_by: [
        asc: :name
      ]
    )
    |> Repo.all(prefix: client_schema)
  end
end
