defmodule AppCount.Vendors.Utils.Orders do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Vendors.Order
  alias AppCount.Vendors.Note
  alias AppCount.Vendors.Vendor
  alias AppCount.Vendors
  alias AppCount.Vendors.Utils.Notes
  alias AppCount.Maintenance.CardItem
  alias AppCount.Tenants.Tenant
  alias AppCount.Core.ClientSchema
  import AppCount.EctoExtensions

  defmacrop notes_query do
    env = AppCount.env()[:environment]
    base_url = "https://s3-us-east-2.amazonaws.com/appcount-maintenance/notes/#{env}/"

    "CASE WHEN max(?) IS NULL AND max(?) IS NULL THEN ARRAY[]::json[] ELSE (array_agg(DISTINCT json_object('{id, text, image, admin, tenant, vendor}', ARRAY[?::text, ?, '#{
      base_url
    }' || ? || '/' || ?, ?, ? || ' ' || ?, ?])::text)::JSON[]) END"
  end

  def list_orders(%ClientSchema{name: client_schema, attrs: admin}) do
    from(
      o in Order,
      left_join: v in assoc(o, :vendor),
      left_join: c in assoc(o, :category),
      left_join: u in assoc(o, :unit),
      left_join: p in assoc(u, :property),
      left_join: t in assoc(o, :tenant),
      left_join: n in assoc(o, :notes),
      left_join: ad in assoc(n, :admin),
      left_join: vendor in assoc(n, :vendor),
      left_join: tenant in assoc(n, :tenant),
      left_join: tech in assoc(n, :tech),
      left_join: card in assoc(o, :card_item),
      select: %{
        id: o.id,
        status: o.status,
        priority: o.priority,
        category: c.name,
        category_id: c.id,
        ticket: o.ticket,
        creation_date: o.creation_date,
        vendor_name: v.name,
        vendor_phone: v.phone,
        vendor_email: v.email,
        vendor_address: v.address,
        vendor_id: v.id,
        tenant: fragment("? || ' ' || ?", t.first_name, t.last_name),
        unit: u.number,
        property_id: p.id,
        inserted_at: o.inserted_at,
        scheduled: o.scheduled,
        updated_at: o.updated_at,
        notes:
          fragment(
            notes_query(),
            n.id,
            card.notes,
            n.id,
            n.text,
            n.id,
            n.image,
            ad.name,
            tenant.first_name,
            tenant.last_name,
            card.notes
          )
      },
      where: u.property_id in ^admin.property_ids,
      #      where: o.status != "Completed",
      order_by: [
        asc: o.creation_date
      ],
      group_by: [o.id, c.id, v.id, t.id, u.id, p.id]
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_orders(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, id) do
    from(
      o in Order,
      left_join: v in assoc(o, :vendor),
      left_join: c in assoc(o, :category),
      left_join: u in assoc(o, :unit),
      left_join: p in assoc(u, :property),
      left_join: t in assoc(o, :tenant),
      left_join: n in assoc(o, :notes),
      left_join: ad in assoc(n, :admin),
      left_join: vendor in assoc(n, :vendor),
      left_join: tenant in assoc(n, :tenant),
      left_join: tech in assoc(n, :tech),
      left_join: card in assoc(o, :card_item),
      select: %{
        id: o.id,
        status: o.status,
        priority: o.priority,
        category: c.name,
        ticket: o.ticket,
        creation_date: o.creation_date,
        tenant: fragment("? || ' ' || ?", t.first_name, t.last_name),
        unit: u.number,
        property: p.name,
        inserted_at: o.inserted_at,
        updated_at: o.updated_at,
        scheduled: o.scheduled,
        has_pet: o.has_pet,
        entry_allowed: o.entry_allowed,
        notes:
          fragment(
            notes_query(),
            n.id,
            card.notes,
            n.id,
            n.text,
            n.id,
            n.image,
            ad.name,
            tenant.first_name,
            tenant.last_name,
            card.notes
          )
      },
      where: v.id == ^id,
      where: p.id in ^admin.property_ids,
      #      where: o.status != "Completed",
      order_by: [
        asc: o.creation_date
      ],
      group_by: [o.id, c.id, v.id, t.id, u.id, p.id]
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_order(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    query =
      from(
        n in Note,
        left_join: t in assoc(n, :tech),
        left_join: a in assoc(n, :admin),
        left_join: ten in assoc(n, :tenant),
        select: %{
          id: n.id,
          order_id: n.order_id,
          tech: t.name,
          tenant: fragment("? || ' ' || ?", ten.first_name, ten.last_name),
          admin: a.name,
          text: n.text,
          inserted_at: n.inserted_at
        }
      )

    from(
      o in Order,
      left_join: v in assoc(o, :vendor),
      left_join: c in assoc(o, :category),
      left_join: u in assoc(o, :unit),
      left_join: p in assoc(u, :property),
      left_join: t in assoc(o, :tenant),
      left_join: n in assoc(o, :notes),
      left_join: nt in subquery(query),
      on: nt.order_id == o.id,
      left_join: tec in assoc(n, :tech),
      left_join: ad in assoc(n, :admin),
      left_join: vendor in assoc(n, :vendor),
      left_join: tenant in assoc(n, :tenant),
      left_join: fp in assoc(u, :floor_plan),
      left_join: tech in assoc(n, :tech),
      left_join: card in assoc(o, :card_item),
      left_join: a in assoc(o, :admin),
      select: %{
        id: o.id,
        type: "vendor",
        status: o.status,
        priority: o.priority,
        vendor_name: v.name,
        vendor_phone: v.phone,
        vendor_email: v.email,
        vendor_address: v.address,
        category: c.name,
        ticket: o.ticket,
        creation_date: o.creation_date,
        tenant: fragment("? || ' ' || ?", t.first_name, t.last_name),
        unit: u.number,
        unit_status: u.status,
        unit_area: u.area,
        unit_floor_plan: fp.name,
        property: p.name,
        property: p.name,
        inserted_at: o.inserted_at,
        updated_at: o.updated_at,
        has_pet: o.has_pet,
        entry_allowed: o.entry_allowed,
        created_by: o.created_by,
        notes: jsonize(nt, [:tech, :admin, :tenant, :id, :text, :inserted_at]),
        scheduled: o.scheduled,
        outsourcer: a.name
      },
      where: o.id == ^id,
      group_by: [o.id, c.id, v.id, t.id, u.id, p.id, n.order_id, a.name, fp.id]
    )
    |> Repo.one(prefix: client_schema)
  end

  def create_order(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %{id: _} = params
      }) do
    wo = Repo.get(AppCount.Maintenance.Order, params["order_id"])
    old_wo = extract_order_data(wo)
    new_attrs = Map.merge(params, old_wo)

    %Order{}
    |> Order.changeset(new_attrs)
    |> Repo.insert(prefix: client_schema)
    |> save_notes(ClientSchema.new(client_schema, params["order_id"]))
    |> remove_maintenance_order(ClientSchema.new(client_schema, params["order_id"]))
  end

  def create_order(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    wo = Repo.get(AppCount.Maintenance.Order, params["order_id"], prefix: client_schema)
    old_wo = extract_order_data(wo)
    # This is the only line different from the function above.
    new_attrs = Map.merge(old_wo, params)

    %Order{}
    |> Order.changeset(new_attrs)
    |> Repo.insert(prefix: client_schema)
    |> save_notes(ClientSchema.new(client_schema, params["order_id"]))
    |> remove_maintenance_order(ClientSchema.new(client_schema, params["order_id"]))
  end

  def create_order(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: params
        },
        m_order
      ) do
    old_wo = extract_order_data(m_order)

    new_attrs =
      Map.merge(
        %{
          "tech_id" => params.tech_id,
          "vendor_id" => params.vendor_id,
          "category_id" => params.vendor_category_id
        },
        old_wo
      )

    %Order{}
    |> Order.changeset(new_attrs)
    |> Repo.insert(prefix: client_schema)
    |> save_notes(m_order.id)
    |> remove_maintenance_order(m_order.id)
  end

  def create_orders(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    Enum.map(params.orders, fn order -> create_order(ClientSchema.new(client_schema, order)) end)
  end

  def create_orders(params) do
    Enum.map(params.orders, fn o -> create_order(o) end)
  end

  def create_new_order(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    params2 = %{
      status: "Open",
      vendor_id: params["vendor_id"],
      category_id: Repo.get_by!(Vendors.Category, name: "Make Ready").id,
      ticket: "0000000000",
      unit_id: params["unit_id"],
      priority: 1,
      card_item_id: params["id"],
      uuid: UUID.uuid4()
    }

    new_params = Map.merge(params2, %{uuid: UUID.uuid4()})

    order =
      %Order{}
      |> Order.changeset(new_params)
      |> Repo.insert!(prefix: client_schema)

    %AppCount.Core.ClientSchema{
      name: client_schema,
      attrs: order
    }
    |> assign_ticket()
  end

  def update_order(params) do
    params = Map.drop(params, [:__meta__, :__struct__])

    Repo.get(Order, params.id)
    |> Order.changeset(params)
    |> Repo.update()
  end

  def mark_make_ready_complete(params) do
    map = %{
      completed: Timex.format!(AppCount.current_time(), "{YYYY}-{0M}-{0D}"),
      completed_by: params.admin
    }

    Repo.get(CardItem, params.card_item_id)
    |> CardItem.changeset(map)
    |> Repo.update()
  end

  def update_order(id, params) do
    order = Repo.get(Order, id)

    params["category"] == "Make Ready" && params["status"] == "Completed" &&
      mark_make_ready_complete(Map.merge(order, %{admin: params["admin"]}))

    new_date = params["scheduled"]
    old_date = to_string(order.scheduled)

    if old_date !== new_date and not is_nil(order.tenant_id) do
      tenant = Repo.get(Tenant, order.tenant_id)
      vendor = Repo.get(Vendor, order.vendor_id)
      category = Repo.get(Vendors.Category, order.category_id)
      unit = Repo.get(AppCount.Properties.Unit, order.unit_id)

      property =
        AppCount.Properties.Utils.Properties.get_property(
          ClientSchema.new("dasmen", unit.property_id)
        )

      cond do
        is_nil(tenant.email) ->
          nil

        true ->
          AppCountCom.WorkOrders.order_date_updated(
            category,
            unit,
            tenant,
            property,
            vendor,
            old_date,
            new_date
          )
      end
    end

    Order.changeset(order, params)
    |> Repo.update()
  end

  def save_notes({:ok, vendor_work_order} = struct, %ClientSchema{name: _client_schema, attrs: id}) do
    AppCount.Core.Tasker.start(fn ->
      notes =
        from(
          n in AppCount.Maintenance.Note,
          where: n.order_id == ^id
        )
        |> Repo.all()

      assignments =
        from(
          n in AppCount.Maintenance.Assignment,
          where: n.order_id == ^id
        )
        |> Repo.all()

      Enum.concat(notes, assignments)
      |> Enum.each(fn note ->
        case extract_note_data(note) do
          nil ->
            nil

          data ->
            Map.merge(data, %{"order_id" => vendor_work_order.id})
            |> Notes.create_note()
        end
      end)
    end)

    struct
  end

  def save_notes({:error, _vendor_work_order} = struct, _id) do
    struct
  end

  def remove_maintenance_order({:ok, _vendor_work_order} = struct, %ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    AppCount.Core.Tasker.start(fn ->
      Repo.get(AppCount.Maintenance.Order, id)
      |> Repo.delete(prefix: client_schema)
    end)

    struct
  end

  def remove_maintenance_order({:error, _vendor_work_order} = struct, _id) do
    struct
  end

  def extract_note_data(%AppCount.Maintenance.Assignment{tech_comments: comment} = note)
      when is_binary(comment) do
    if is_nil(comment) do
      "[No text]"
    else
      comment
    end

    %{
      "text" => comment,
      "admin_id" => note.admin_id,
      "tech_id" => note.tech_id,
      "inserted_at" => note.inserted_at
    }
  end

  def extract_note_data(%AppCount.Maintenance.Note{} = note) do
    new_note =
      if is_nil(note.text) do
        Map.replace!(note, :text, "[No text]")
      else
        note
      end

    %{
      "text" => new_note.text,
      "image" => note.image,
      "admin_id" => note.admin_id,
      "tech_id" => note.tech_id,
      "tenant_id" => note.tenant_id,
      "inserted_at" => note.inserted_at
    }
  end

  def extract_note_data(_note), do: nil

  def extract_order_data(order) do
    %{
      "uuid" => order.uuid || UUID.uuid4(),
      "ticket" => order.ticket,
      "priority" => order.priority,
      "unit_id" => order.unit_id,
      "tenant_id" => order.tenant_id,
      "card_item_id" => order.card_item_id,
      "creation_date" => order.inserted_at
    }
  end

  def convert_param(order) do
    %{
      "vendor_id" => order.vendor_id,
      "order_id" => order.id,
      "category_id" => order.vendor_category_id
    }
  end

  defp assign_ticket(%{id: id} = order) do
    ticket =
      :crypto.hash(:md5, "#{id}")
      |> Base.encode16()
      |> String.slice(22, 10)

    order
    |> Order.changeset(%{ticket: ticket})
    |> Repo.update!()
  end

  def delete_order(id) do
    Repo.get(Order, id)
    |> Repo.delete()
  end

  #  defp send_email(email, name, order, params \\ nil) do
  #    from(
  #      v in Vendor,
  #      join: o in assoc(v, :orders),
  #      where: o.id == ^order.id,
  #      select: v.name
  #    )
  #    |> Repo.one
  #    case params["scheduled"] do
  #      nil ->
  #    end
  #  end
end
