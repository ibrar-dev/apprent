defmodule AppCount.Reports.MaintenanceReport do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Maintenance.Utils.OpenHistories
  alias AppCount.Maintenance.Card
  alias AppCount.Maintenance.CardItem
  alias AppCount.Maintenance.Order
  alias AppCount.Properties.Property
  alias AppCount.Core.ClientSchema

  def open_make_ready_report(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        date \\ nil
      ) do
    new_date =
      cond do
        is_nil(date) ->
          nil

        true ->
          Timex.parse!(date, "{YYYY}-{0M}-{D}")
          |> Timex.end_of_day()
      end

    property_ids =
      Admins.property_ids_for(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      })

    Enum.map(
      property_ids,
      fn property_id ->
        %{
          property: get_property_info(property_id),
          open_orders: get_open_orders(ClientSchema.new(client_schema, property_id), new_date),
          not_ready_units: get_not_ready_units(property_id, date),
          not_inspected_units: get_not_inspected_units(property_id, new_date)
        }
      end
    )
    |> Enum.sort_by(& &1.property.name)
  end

  @doc """
  admin - ClientSchema{name: client_schema, %Admin{}}
  start_date - "2020-01-01" (string)
  end_date - "2020-10-10" (string)
  """
  def property_metrics(
        %ClientSchema{name: _client_schema, attrs: _admin} = schema,
        start_date,
        end_date
      ) do
    make_readies = make_ready_report(schema, start_date, end_date)
    open_make_ready = open_make_ready_report(schema, end_date)
    callback_counts = callbacks_report(schema, start_date, end_date)

    make_readies
    |> Enum.map(fn p ->
      omr = Enum.find(open_make_ready, fn x -> x.property.id == p.id end)
      cb = Enum.find(callback_counts, fn x -> x.property_id == p.id end)

      Map.merge(
        omr,
        %{
          make_ready_units: p.units,
          completion_time: p.completion_time,
          callback_count: cb.callback_count
        }
      )
    end)
  end

  def get_open_orders(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: property_id
        },
        nil
      ) do
    from(
      o in Order,
      where: o.status in ["unassigned", "assigned"] and o.property_id == ^property_id,
      select: count(o.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def get_open_orders(property_id, date), do: OpenHistories.list_property_open(property_id, date)

  def callbacks_report(%ClientSchema{name: _client_schema, attrs: admin}, start_date, end_date) do
    from_date =
      start_date
      |> Date.from_iso8601!()
      |> Timex.to_datetime()
      |> Timex.beginning_of_day()

    to_date =
      end_date
      |> Date.from_iso8601!()
      |> Timex.to_datetime()
      |> Timex.end_of_day()

    range =
      AppCount.Core.DateTimeRange.new(
        from_date,
        to_date
      )

    # Given all properties and all callbacks, we should get a map where the key
    # is the property id and the value is the number of callbacks
    # TODO Schema this
    callback_counts =
      AppCount.Maintenance.AssignmentRepo.get_callback_assignments(
        admin.property_ids,
        range
      )
      |> Enum.frequencies_by(fn callback -> callback.order.property_id end)

    admin.property_ids
    |> Enum.map(fn id ->
      %{
        property_id: id,
        callback_count: callback_counts[id] || 0
      }
    end)
  end

  def make_ready_report(%ClientSchema{name: client_schema, attrs: admin}, start_date, end_date) do
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
        join: u in assoc(c, :unit),
        select: %{
          id: c.id,
          inserted_at: c.inserted_at,
          completion: c.completion,
          unit: u.number,
          admin: c.admin,
          completed_at: ci.completed,
          property_id: u.property_id,
          move_out_date: c.move_out_date,
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

  defp get_not_ready_units(property_id, nil) do
    item_query =
      from(
        i in CardItem,
        select: %{
          card_id: i.card_id,
          id: i.id
        },
        where: is_nil(i.completed)
      )

    from(
      c in Card,
      join: u in assoc(c, :unit),
      join: p in assoc(u, :property),
      join: i in subquery(item_query),
      on: i.card_id == c.id,
      where: u.property_id == ^property_id,
      select: %{
        id: c.id,
        move_out: c.move_out_date,
        property: p.name,
        unit: u.number,
        lease_id: c.lease_id
      },
      distinct: u.id
    )
    |> Repo.all()
  end

  defp get_not_ready_units(property_id, date) do
    item_query =
      from(
        i in CardItem,
        select: %{
          card_id: i.card_id,
          id: i.id,
          completed: i.completed
        },
        where: i.completed > ^date or is_nil(i.completed)
      )

    from(
      c in Card,
      join: u in assoc(c, :unit),
      join: p in assoc(u, :property),
      join: i in subquery(item_query),
      on: i.card_id == c.id,
      where: u.property_id == ^property_id,
      where: c.move_out_date < ^date,
      where: is_nil(c.bypass_date),
      select: %{
        id: c.id,
        move_out: c.move_out_date,
        property: p.name,
        unit: u.number,
        unit_id: c.unit_id
      },
      distinct: u.id
    )
    |> Repo.all()
  end

  def get_not_inspected_units(property_id, nil),
    do: get_not_inspected_units(property_id, AppCount.current_time())

  def get_not_inspected_units(property_id, date) do
    from(
      u in AppCount.Properties.Unit,
      join: l in assoc(u, :leases),
      left_join: c in assoc(u, :cards),
      where: not is_nil(l.actual_move_out) and l.actual_move_out <= ^date,
      where: is_nil(l.renewal_id),
      where: is_nil(c.id) or c.inserted_at > ^date,
      where: u.property_id == ^property_id,
      having: count(l.id, :distinct) > count(c.id, :distinct),
      select: %{
        id: u.id,
        unit: u.number,
        lease_end: max(l.end_date),
        move_out: max(l.actual_move_out)
      },
      group_by: [u.id]
    )
    |> Repo.all()
  end

  defp get_property_info(property_id) do
    from(
      p in AppCount.Properties.Property,
      left_join: i in assoc(p, :icon_url),
      where: p.id == ^property_id,
      select: %{
        id: p.id,
        name: p.name,
        icon: i.url
      },
      limit: 1
    )
    |> Repo.one()
  end
end
