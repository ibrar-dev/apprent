defmodule AppCount.Maintenance.Utils.Queries.Orders do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Note
  alias AppCount.Vendors
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema

  def list_orders(admin, dates, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_id
      })
      when is_integer(property_id),
      do: list_orders(admin, dates, ClientSchema.new(client_schema, [property_id]))

  # Split up this function to make testing better. Problem only happens on prod
  def list_orders(admin, dates, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: provided_property_ids
      }) do
    parsed_dates = get_dates(dates)

    # Only use property IDs this admin has access to and that were provided with
    # the query
    admin_property_ids = admin.property_ids

    property_ids =
      provided_property_ids
      |> Enum.filter(fn el -> el in admin_property_ids end)

    list_orders_query(parsed_dates, property_ids)
    |> Repo.all(timeout: 50_000, prefix: client_schema)
    |> group_by_status
    |> combine_with_vendors(admin, parsed_dates, %AppCount.Core.ClientSchema{
      name: client_schema,
      attrs: property_ids
    })
  end

  def list_orders_query(parsed_dates, property_ids) do
    from(
      order in Order,
      left_join: tenant in assoc(order, :tenant),
      left_join: unit in assoc(order, :unit),
      join: category in assoc(order, :category),
      join: parent_cat in assoc(category, :parent),
      join: property in assoc(order, :property),
      left_join: card in subquery(card_query()),
      on: order.id == card.order_id,
      left_join: note in subquery(note_count_query()),
      on: note.order_id == order.id,
      left_join: assignment in subquery(assignment_query()),
      on: assignment.order_id == order.id,
      left_join: completed_assignment in subquery(completed_at_query()),
      on: completed_assignment.order_id == order.id,
      where: order.property_id in ^property_ids,
      where: parent_cat.name != "Make Ready",
      where:
        between(order.inserted_at, ^List.first(parsed_dates), ^List.last(parsed_dates)) or
          between(
            completed_assignment.completed_at,
            ^List.first(parsed_dates),
            ^List.last(parsed_dates)
          ),
      select:
        map(
          order,
          [
            :id,
            :entry_allowed,
            :has_pet,
            :priority,
            :no_access,
            :ticket,
            :cancellation,
            :inserted_at,
            :property_id,
            :created_by,
            :status
          ]
        ),
      select_merge: %{
        assignments: assignment.assignments,
        completed_at: completed_assignment.completed_at,
        notes_count: note.count,
        card: card.card,
        category: category.name,
        category_id: category.id,
        parent_category: parent_cat.name,
        parent_category_id: parent_cat.id,
        property: property.name,
        type: "Maintenance",
        tenant: map(tenant, [:id, :first_name, :last_name, :email]),
        unit: %{
          id: unit.id,
          number: unit.number,
          area: unit.area
        }
      }
    )
  end

  def list_orders_type(%AppCount.Core.ClientSchema{name: client_schema, attrs: property_id}, type) do
    types = String.split(type, ",")

    from(
      o in Order,
      join: u in assoc(o, :unit),
      join: c in assoc(o, :category),
      join: pc in assoc(c, :parent),
      where: o.status in ^types and o.property_id == ^property_id,
      select: %{
        id: o.id,
        unit_id: o.unit_id,
        unit: u.number,
        status: o.status,
        category: fragment("? || ' ' || ?", pc.name, c.name)
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def group_by_status(orders) do
    groups = %{unassigned: [], assigned: [], completed: [], cancelled: []}

    Enum.reduce(
      orders,
      groups,
      fn o, acc ->
        Map.update!(acc, String.to_atom(order_status(o)), fn _ ->
          acc[String.to_atom(order_status(o))] ++ [o]
        end)
      end
    )
  end

  def get_status(%{cancellation: c}) when not is_nil(c),
    do: "cancelled"

  def get_status(%{card: c}) when not is_nil(c) do
    case List.first(c)["completed"] do
      nil -> "unassigned"
      _ -> "completed"
    end
  end

  def get_status(%{assignments: []}), do: "unassigned"

  def get_status(%{assignments: a}) when is_nil(a), do: "unassigned"

  def get_status(%{assignments: a}) do
    case List.first(a)["status"] do
      "withdrawn" -> "unassigned"
      "callback" -> "unassigned"
      "rejected" -> "unassigned"
      "on_hold" -> "assigned"
      "in_progress" -> "assigned"
      s -> s
    end
  end

  def order_status(o), do: get_status(o)

  # def order_status(%{status: status}), do: status

  def completed_at_query() do
    from(
      a in Assignment,
      where: a.status == "completed",
      select: %{order_id: a.order_id, completed_at: a.completed_at}
    )
  end

  def assignment_query() do
    from(
      a in Assignment,
      join: t in assoc(a, :tech),
      left_join: ad in assoc(a, :admin),
      select: %{
        order_id: a.order_id,
        assignments:
          jsonize(
            a,
            [
              :id,
              :status,
              :rating,
              :completed_at,
              :inserted_at,
              :confirmed_at,
              :tech_comments,
              :updated_at,
              :email,
              :tech_id,
              :admin_id,
              {:creator, ad.name},
              {:tech, t.name}
            ],
            a.inserted_at,
            "DESC"
          )
      },
      group_by: [a.order_id]
    )
  end

  def card_query() do
    from(
      o in Order,
      join: c in assoc(o, :card_item),
      left_join: t in assoc(c, :tech),
      left_join: v in assoc(c, :vendor),
      select: %{
        order_id: o.id,
        card:
          jsonize(c, [
            :id,
            :name,
            :scheduled,
            :completed,
            :completed_by,
            {:tech, t.name},
            {:vendor, v.name}
          ])
      },
      group_by: [o.id, c.id]
    )
  end

  def note_count_query() do
    from(
      n in Note,
      select: %{
        order_id: n.order_id,
        count: count(n.id)
      },
      group_by: [n.order_id]
    )
  end

  def combine_with_vendors(maintenance, admin, dates, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    vendor_orders = vendor_orders(ClientSchema.new(client_schema, admin), dates, property_ids)
    Map.merge(maintenance, vendor_orders, fn _, m, v -> add_and_sort(m, v) end)
  end

  def add_and_sort(m, v) do
    (m ++ v)
    |> Enum.sort_by(& &1.inserted_at)
  end

  def vendor_orders(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        dates,
        property_ids
      ) do
    admin_property_ids = admin.property_ids

    from(
      o in Vendors.Order,
      join: u in assoc(o, :unit),
      join: p in assoc(u, :property),
      left_join: t in assoc(o, :tenant),
      join: c in assoc(o, :category),
      join: v in assoc(o, :vendor),
      left_join: n in subquery(vendor_notes_count_query()),
      on: n.order_id == o.id,
      where: u.property_id in ^property_ids and u.property_id in ^admin_property_ids,
      where:
        between(o.inserted_at, ^List.first(dates), ^List.last(dates)) or
          between(o.updated_at, ^List.first(dates), ^List.last(dates)),
      select:
        map(o, [
          :id,
          :status,
          :priority,
          :ticket,
          :creation_date,
          :scheduled,
          :created_by,
          :inserted_at,
          :updated_at
        ]),
      select_merge: %{
        notes_count: n.count,
        tenant: map(t, [:id, :first_name, :last_name, :email]),
        unit: %{
          id: u.id,
          number: u.number,
          area: u.area
        },
        vendor: %{
          id: v.id,
          name: v.name
        },
        category: c.name,
        category_id: c.id,
        property: p.name,
        type: "Vendor"
      }
    )
    |> Repo.all(prefix: client_schema)
    |> group_by_vendor_status
  end

  def vendor_notes_count_query() do
    from(
      note in Vendors.Note,
      select: %{
        order_id: note.order_id,
        count: count(note.id)
      },
      group_by: [note.order_id]
    )
  end

  def group_by_vendor_status(orders) do
    groups = %{assigned: [], completed: [], cancelled: []}

    Enum.reduce(
      orders,
      groups,
      fn o, acc ->
        Map.update!(acc, vendor_status(o.status), fn _ -> acc[vendor_status(o.status)] ++ [o] end)
      end
    )
  end

  def vendor_status("Open"), do: :assigned
  def vendor_status("Completed"), do: :completed
  def vendor_status("Cancelled"), do: :cancelled

  def get_dates(nil) do
    start_d = ~N[2020-06-01 00:00:00]

    end_d =
      Timex.today()
      |> Timex.to_naive_datetime()
      |> Timex.end_of_day()

    [start_d, end_d]
  end

  def get_dates(""), do: get_dates(nil)

  def get_dates(dates) do
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
