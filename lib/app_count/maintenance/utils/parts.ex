defmodule AppCount.Maintenance.Utils.Parts do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Maintenance.Part
  alias AppCount.Maintenance.Order
  alias AppCount.Properties.Unit
  alias AppCount.Tenants.Tenant
  alias AppCount.Core.ClientSchema
  # status: %{
  # pending: order just placed on parts hold, email resident, cannot assign order.
  # ordered: part has been ordered, email resident, cannot assign order.
  # delivered: part has been received, email resident, can assign order.
  # canceled: part is no longer needed, can assign order.
  # }

  def list_parts_for_dashboard(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      p in Part,
      join: o in assoc(p, :order),
      left_join: u in assoc(o, :unit),
      left_join: pr in assoc(u, :property),
      select: %{
        id: p.id,
        order_id: p.order_id,
        name: p.name,
        status: p.status,
        unit: u.number,
        property: pr.name,
        inserted_at: p.inserted_at,
        updated_at: p.updated_at
      },
      where:
        (o.property_id in ^property_ids or pr.id in ^property_ids) and
          p.status in ["pending", "ordered"] and is_nil(o.cancellation),
      group_by: [o.id, pr.id, u.id, p.id]
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_part(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    part =
      %Part{}
      |> Part.changeset(params)
      |> Repo.insert(prefix: client_schema)

    %AppCount.Core.ClientSchema{
      name: client_schema,
      attrs: part
    }
    |> notify_resident
  end

  def update_part(id, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    part =
      Repo.get(Part, id, prefix: client_schema)
      |> Part.changeset(params)
      |> Repo.update(prefix: client_schema)

    %AppCount.Core.ClientSchema{
      name: client_schema,
      attrs: part
    }
    |> notify_resident
  end

  def update_parts(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: parts
      }) do
    Enum.each(parts, fn x ->
      part =
        Repo.get(Part, x["id"])
        |> Part.changeset(%{status: x["status"]})
        |> Repo.update(prefix: client_schema)

      %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: part
      }
      |> notify_resident
    end)
  end

  def remove_part(id) do
    Repo.get(Part, id)
    |> Repo.delete()
  end

  def notify_resident({:error, _}), do: nil

  def notify_resident(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: {:ok, part}
      }) do
    from(
      o in Order,
      where: o.id == ^part.order_id,
      select: o.tenant_id
    )
    |> Repo.one(prefix: client_schema)
    |> send_email(Repo.get(Part, part.id, prefix: client_schema))
  end

  def send_email(nil, _), do: nil

  def send_email(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: tenant_id
        },
        part
      ) do
    now =
      AppCount.current_time()
      |> Timex.to_date()

    lease_query =
      from(
        l in AppCount.Leases.Lease,
        join: o in assoc(l, :occupancies),
        where:
          is_nil(l.move_out_date) and l.start_date <= ^now and
            (l.end_date >= ^now or is_nil(l.renewal_id)),
        select: %{
          id: l.id,
          tenant_id: o.tenant_id,
          unit_id: l.unit_id
        }
      )

    {email, name, property_id} =
      from(
        t in Tenant,
        join: l in subquery(lease_query),
        on: l.tenant_id == t.id,
        join: u in Unit,
        on: l.unit_id == u.id,
        join: p in assoc(u, :property),
        select: {t.email, fragment("? || ' ' || ?", t.first_name, t.last_name), p.id},
        where: t.id == ^tenant_id
      )
      |> Repo.one(prefix: client_schema)

    property = AppCount.Properties.get_property(ClientSchema.new("dasmen", property_id))
    order = Repo.get(Order, part.order_id)
    AppCountCom.Parts.part_updated(part, email, name, order.ticket, property)
  end
end
