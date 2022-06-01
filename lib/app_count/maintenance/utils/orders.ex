defmodule AppCount.Maintenance.Utils.Orders do
  import Ecto.Query
  import AppCount.EctoExtensions
  import AppCount.Utils
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Note
  alias AppCount.Maintenance.CardItem
  alias AppCount.Maintenance.Part
  alias AppCount.Maintenance.Tech
  alias AppCount.Admins
  alias AppCount.Repo
  alias AppCount.Maintenance.Utils.OrderPublisher
  alias AppCount.Core.ClientSchema

  def list_orders(property_id, start_date, end_date) do
    property_order_query(property_id, start_date, end_date)
    |> Repo.all()
  end

  def get_order(admin, id) do
    Admins.property_ids_for(admin)
    |> order_query(id)
    |> Repo.one()
  end

  def get_order_tenant(property_id, id) do
    order_query([property_id], id)
    |> Repo.one()
  end

  def get_tenants_orders(id) do
    id
    |> tenant_order_query
    |> Repo.all()
  end

  def update_order(id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    {_, order} =
      Repo.get(Order, id, prefix: client_schema)
      |> Repo.preload([:category, :unit, :property])
      |> Order.changeset(params)
      |> Repo.update(prefix: client_schema)
      |> notify_resident(params)

    if params["priority"] == 3 do
      property =
        AppCount.Properties.get_property(ClientSchema.new(client_schema, order.property_id))

      Admins.admins_for(
        ClientSchema.new(client_schema, order.property_id),
        ["Tech"]
      )
      |> Enum.map(fn t -> notify_techs(t, Map.put(order, :property, property)) end)
    end
  end

  # UNTESTED
  # created by site staff
  def create_order(%AppCount.Core.ClientSchema{name: client_schema, attrs: attrs}) do
    admin_id =
      case indifferent(attrs, :admin_id) do
        nil -> nil
        id -> id
      end

    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert!(prefix: client_schema)
    |> OrderPublisher.publish_order_created_event()
    |> assign_ticket()
    |> create_order_note(indifferent(attrs, :note), nil, admin_id)
    |> create_order_note(indifferent(attrs, :text), nil, admin_id)
    |> create_note_image(indifferent(attrs, :attachment), admin_id)
    |> assign_to_tech(admin_id, attrs["tech"], client_schema)
  end

  # UNTESTED
  # created by site staff
  def create_order(admin_id, %AppCount.Core.ClientSchema{name: client_schema, attrs: attrs}) do
    new_params = Map.merge(attrs, %{"uuid" => UUID.uuid4()})

    %Order{}
    |> Order.changeset(new_params)
    |> Repo.insert(prefix: client_schema)
    |> case do
      {:ok, order} ->
        OrderPublisher.publish_order_created_event(order)
        |> assign_ticket()
        |> create_order_note(attrs["note"], attrs["image"], admin_id)
        |> create_note_image(attrs["attachment"], admin_id)
        |> assign_to_tech(admin_id, attrs["tech"], client_schema)

      e ->
        e
    end
  end

  def notify_resident({:ok, order}, _params), do: {:ok, order}
  def notify_resident(_order, _params), do: nil

  def assign_to_tech(order, _, nil, _client_schema),
    do: assign_status({:ok, order}, order.id, "unassigned")

  def assign_to_tech(order, admin_id, tech, client_schema) do
    AppCount.Core.Tasker.start(fn ->
      AppCount.Maintenance.assign_order(ClientSchema.new(client_schema, order.id), tech, admin_id)
    end)

    {:ok, order}
  end

  def create_note_image(order, nil, _), do: order

  def create_note_image(order, attachment, admin_id) do
    AppCount.Core.Tasker.start(fn ->
      %Note{}
      |> Note.changeset(%{attachment: attachment, admin_id: admin_id, order_id: order.id})
      |> Repo.insert()
    end)

    order
  end

  def create_order_note(order, nil, nil, _), do: order

  def create_order_note(order, note, nil, admin_id) do
    AppCount.Core.Tasker.start(fn ->
      attrs =
        %{order_id: order.id, text: note}
        |> assign_note(order.tenant_id, admin_id)

      %Note{}
      |> Note.changeset(attrs)
      |> Repo.insert!()
    end)

    order
  end

  def create_order_note(order, note, image, admin_id) do
    AppCount.Core.Tasker.start(fn ->
      attrs =
        %{order_id: order.id, image: image.filename}
        |> assign_note(order.tenant_id, admin_id)

      n =
        %Note{}
        |> Note.changeset(attrs)
        |> Repo.insert!()

      file_binary = File.read!(image.path)
      AppCount.Maintenance.Utils.Notes.put_image(n.id, image.filename, file_binary)
      create_order_note(order, note, nil, admin_id)
    end)

    order
  end

  defp assign_note(params, nil, admin_id), do: Map.put(params, :admin_id, admin_id)
  defp assign_note(params, tenant_id, _), do: Map.put(params, :tenant_id, tenant_id)

  defmacrop notes_query do
    env = AppCount.env()[:environment]
    base_url = "https://s3-us-east-2.amazonaws.com/appcount-maintenance/notes/#{env}/"

    "CASE WHEN max(?) IS NULL AND max(?) IS NULL THEN ARRAY[]::json[] ELSE (array_agg(json_object('{id, text, image, admin, tenant, tech, card, inserted_at}', ARRAY[?::text, ?, '#{
      base_url
    }' || ? || '/' || ?, ?, ? || ' ' || ?, ?, ?, ?::text]) ORDER BY ? ASC)) END"
  end

  defp order_query(property_ids, id) do
    assignment_query =
      from(
        a in Assignment,
        left_join: t in assoc(a, :tech),
        left_join: admin in assoc(a, :admin),
        select: %{
          order_id: a.order_id,
          assignments:
            jsonize(
              a,
              [
                :id,
                :status,
                :tech_id,
                :order_id,
                :materials,
                :rating,
                :tenant_comment,
                :tech_comments,
                :confirmed_at,
                :completed_at,
                :updated_at,
                :inserted_at,
                :callback_info,
                :rating,
                :history,
                :email,
                {:tech, t.name},
                {:admin, admin.name}
              ],
              a.inserted_at,
              "DESC"
            )
        },
        where: a.order_id == ^id,
        group_by: a.order_id
      )

    parts_query =
      from(
        p in Part,
        select: %{
          order_id: p.order_id,
          parts: jsonize(p, [:id, :status, :name, :inserted_at, :updated_at])
        },
        group_by: p.order_id
      )

    from(
      wo in Order,
      left_join: u in assoc(wo, :unit),
      left_join: a in subquery(assignment_query),
      on: a.order_id == wo.id,
      left_join: part in subquery(parts_query),
      on: part.order_id == wo.id,
      left_join: c in assoc(wo, :category),
      left_join: fp in assoc(u, :floor_plan),
      left_join: sc in assoc(c, :parent),
      left_join: te in assoc(wo, :tenant),
      left_join: p in assoc(wo, :property),
      left_join: n in assoc(wo, :notes),
      left_join: admin in assoc(n, :admin),
      left_join: tenant in assoc(n, :tenant),
      left_join: tech in assoc(n, :tech),
      left_join: card_item in assoc(wo, :card_item),
      where: wo.property_id in ^property_ids or u.property_id in ^property_ids,
      order_by: [
        asc: wo.inserted_at
      ],
      select: %{
        id: wo.id,
        tenant: fragment("? || ' ' || ?", te.first_name, te.last_name),
        tenant_email: te.email,
        alarm_code: te.alarm_code,
        submitted: wo.inserted_at,
        has_pet: wo.has_pet,
        entry_allowed: wo.entry_allowed,
        priority: wo.priority,
        attempt: wo.no_access,
        ticket: wo.ticket,
        notes:
          fragment(
            notes_query(),
            n.id,
            card_item.notes,
            n.id,
            n.text,
            n.id,
            n.image,
            admin.name,
            tenant.first_name,
            tenant.last_name,
            tech.name,
            card_item.notes,
            n.inserted_at,
            n.inserted_at
          ),
        no_access: wo.no_access,
        parts: cond_array(part.parts),
        assignments: cond_array(a.assignments),
        property_id: p.id,
        unit: u.number,
        unit_status: u.status,
        unit_area: u.area,
        unit_floor_plan: fp.name,
        cancellation: wo.cancellation,
        created_by: wo.created_by,
        property: %{
          id: p.id,
          name: p.name,
          lat: type(p.lat, :float),
          lng: type(p.lng, :float)
        },
        category: fragment("? || ' > ' || ?", sc.name, c.name),
        category_id: c.id,
        third_party: c.third_party
      },
      where: wo.id == ^id,
      group_by: [
        wo.id,
        te.id,
        p.id,
        u.number,
        sc.id,
        c.id,
        a.assignments,
        part.parts,
        u.id,
        fp.id
      ]
    )
  end

  def s_query(id) do
    from(
      o in Order,
      left_join: a in assoc(o, :assignments),
      select: %{
        order_id: o.id,
        status: a.status,
        completed_date: a.completed_at
      },
      group_by: [o.id, a.id],
      order_by: [desc: a.inserted_at],
      where: o.id == ^id
    )
  end

  def property_order_query(property_id, start_date, end_date) do
    assignment_query =
      from(
        a in Assignment,
        left_join: t in assoc(a, :tech),
        select: %{
          order_id: a.order_id,
          status:
            fragment("CASE WHEN 'completed' = ANY(array_agg(?)) THEN 1 ELSE 0 END", a.status),
          assignments:
            jsonize(
              a,
              [
                :id,
                :status,
                :tech_id,
                {:tech, t.name},
                :inserted_at,
                :updated_at,
                :confirmed_at,
                :completed_at,
                :tech_comments,
                :rating
              ],
              a.inserted_at,
              "DESC"
            )
        },
        group_by: a.order_id
      )

    parts_query =
      from(
        p in Part,
        where: p.status in ["pending", "ordered"],
        select: %{
          order_id: p.order_id,
          parts: jsonize(p, [:id, :status, :name])
        },
        group_by: p.order_id
      )

    from(
      wo in Order,
      left_join: u in assoc(wo, :unit),
      left_join: a in subquery(assignment_query),
      on: a.order_id == wo.id,
      left_join: part in subquery(parts_query),
      on: part.order_id == wo.id,
      left_join: te in assoc(wo, :tenant),
      left_join: c in assoc(wo, :category),
      left_join: sc in assoc(c, :parent),
      left_join: p in assoc(wo, :property),
      select:
        map(
          wo,
          [
            :id,
            :cancellation,
            :property_id,
            :ticket,
            :inserted_at,
            :priority,
            :card_item_id,
            :no_access,
            :created_by
          ]
        ),
      select_merge: %{
        assignments: cond_array(a.assignments),
        parts: cond_array(part.parts),
        unit: u.number,
        tenant: fragment("? || ' ' || ?", te.first_name, te.last_name),
        category: fragment("? || ' > ' || ?", sc.name, c.name),
        category_id: c.id,
        third_party: c.third_party,
        property: %{
          name: p.name
        }
      },
      where: wo.property_id == ^property_id,
      where:
        between(wo.inserted_at, ^start_date, ^end_date) or
          between(wo.updated_at, ^start_date, ^end_date),
      order_by: [
        asc: wo.inserted_at
      ]
    )
  end

  def order_query(property_ids) do
    assignment_query =
      from(
        a in Assignment,
        left_join: t in assoc(a, :tech),
        select: %{
          order_id: a.order_id,
          #            a.status,
          status:
            fragment("CASE WHEN 'completed' = ANY(array_agg(?)) THEN 1 ELSE 0 END", a.status),
          assignments:
            jsonize(
              a,
              [
                :id,
                :status,
                :tech_id,
                {:tech, t.name},
                :inserted_at,
                :updated_at,
                :confirmed_at,
                :completed_at,
                :tech_comments,
                :rating
              ],
              a.inserted_at,
              "DESC"
            )
        },
        group_by: [a.order_id, a.status]
      )

    parts_query =
      from(
        p in Part,
        where: p.status in ["pending", "ordered"],
        select: %{
          order_id: p.order_id,
          parts: jsonize(p, [:id, :status, :name])
        },
        group_by: p.order_id
      )

    from(
      wo in Order,
      left_join: u in assoc(wo, :unit),
      left_join: a in subquery(assignment_query),
      on: a.order_id == wo.id,
      left_join: part in subquery(parts_query),
      on: part.order_id == wo.id,
      left_join: te in assoc(wo, :tenant),
      left_join: c in assoc(wo, :category),
      left_join: sc in assoc(c, :parent),
      left_join: p in assoc(wo, :property),
      select:
        map(
          wo,
          [
            :id,
            :cancellation,
            :property_id,
            :ticket,
            :inserted_at,
            :priority,
            :card_item_id,
            :no_access,
            :created_by
          ]
        ),
      select_merge: %{
        assignments: cond_array(a.assignments),
        status: a.status,
        parts: cond_array(part.parts),
        unit: u.number,
        tenant: fragment("? || ' ' || ?", te.first_name, te.last_name),
        tenant_email: te.email,
        category: fragment("? || ' > ' || ?", sc.name, c.name),
        category_id: c.id,
        third_party: c.third_party,
        property: %{
          name: p.name
        }
      },
      distinct: wo.id,
      group_by: [
        wo.id,
        a.assignments,
        part.parts,
        u.number,
        te.first_name,
        te.last_name,
        te.email,
        sc.name,
        c.name,
        c.id,
        p.name,
        a.status
      ],
      where: wo.property_id in ^property_ids,
      order_by: [
        desc: wo.inserted_at
      ]
    )
  end

  def tenant_order_query(%AppCount.Core.ClientSchema{attrs: id}) do
    # Temproary Patch to get production working again.
    # HB: https://app.honeybadger.io/projects/79008/faults/80406741
    # TODO remove this when
    tenant_order_query(id)
  end

  def tenant_order_query(id) do
    assignment_query =
      from(
        a in Assignment,
        left_join: t in assoc(a, :tech),
        left_join: admin in assoc(a, :admin),
        select: %{
          order_id: a.order_id,
          assignments:
            jsonize(
              a,
              [
                :id,
                :status,
                :tech_id,
                :order_id,
                :materials,
                :rating,
                :tech_comments,
                :confirmed_at,
                :completed_at,
                :updated_at,
                :inserted_at,
                :callback_info,
                :rating,
                :history,
                :email,
                {:tech, t.name},
                {:admin, admin.name}
              ],
              a.inserted_at,
              "DESC"
            )
        },
        group_by: a.order_id
      )

    parts_query =
      from(
        p in Part,
        select: %{
          order_id: p.order_id,
          parts: jsonize(p, [:id, :status, :name, :inserted_at, :updated_at])
        },
        group_by: p.order_id
      )

    from(
      wo in Order,
      left_join: u in assoc(wo, :unit),
      left_join: a in subquery(assignment_query),
      on: a.order_id == wo.id,
      # left_join: o in assoc(wo, :offers),
      left_join: part in subquery(parts_query),
      on: part.order_id == wo.id,
      left_join: c in assoc(wo, :category),
      left_join: fp in assoc(u, :floor_plan),
      left_join: sc in assoc(c, :parent),
      left_join: te in assoc(wo, :tenant),
      left_join: p in assoc(wo, :property),
      left_join: n in assoc(wo, :notes),
      left_join: admin in assoc(n, :admin),
      left_join: tenant in assoc(n, :tenant),
      left_join: tech in assoc(n, :tech),
      left_join: card_item in assoc(wo, :card_item),
      order_by: [
        desc: wo.inserted_at
      ],
      select: %{
        id: wo.id,
        tenant: fragment("? || ' ' || ?", te.first_name, te.last_name),
        alarm_code: te.alarm_code,
        submitted: wo.inserted_at,
        has_pet: wo.has_pet,
        entry_allowed: wo.entry_allowed,
        priority: wo.priority,
        attempt: wo.no_access,
        ticket: wo.ticket,
        notes:
          fragment(
            notes_query(),
            n.id,
            card_item.notes,
            n.id,
            n.text,
            n.id,
            n.image,
            admin.name,
            tenant.first_name,
            tenant.last_name,
            tech.name,
            card_item.notes,
            n.inserted_at,
            n.inserted_at
          ),
        no_access: wo.no_access,
        parts: cond_array(part.parts),
        assignments: cond_array(a.assignments),
        # offers: jsonize(o, [:id, :tech_id]),
        property_id: p.id,
        unit: u.number,
        unit_status: u.status,
        unit_area: u.area,
        unit_floor_plan: fp.name,
        cancellation: wo.cancellation,
        created_by: wo.created_by,
        property: %{
          id: p.id,
          name: p.name,
          lat: type(p.lat, :float),
          lng: type(p.lng, :float)
        },
        category: sc.name,
        subcategory: c.name,
        category_id: sc.id,
        subcategory_id: c.id
      },
      where: te.id == ^id,
      group_by: [
        wo.id,
        te.id,
        p.id,
        u.number,
        sc.id,
        c.id,
        a.assignments,
        part.parts,
        u.id,
        fp.id
      ]
    )
  end

  def delete_order(admin, id, reason) do
    Repo.get(Order, id)
    |> Order.changeset(%{
      cancellation: %{
        admin: admin,
        time: AppCount.current_time(),
        reason: reason
      },
      status: "cancelled"
    })
    |> Repo.update()
    |> case do
      {:ok, order} ->
        if !is_nil(order.tenant_id) do
          {email, name, ticket, cancellation, property} =
            from(
              o in Order,
              join: u in assoc(o, :unit),
              join: p in assoc(u, :property),
              left_join: l in assoc(p, :logo_url),
              left_join: t in assoc(o, :tenant),
              where: o.id == ^order.id,
              select: {
                t.email,
                fragment("? || ' ' || ?", t.first_name, t.last_name),
                o.ticket,
                o.cancellation,
                merge(p, %{logo: l.url})
              }
            )
            |> Repo.one()

          cond do
            !third_party(id) && !is_nil(email) ->
              AppCountCom.WorkOrders.order_cancelled(email, name, ticket, cancellation, property)

            true ->
              nil
          end
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def notify_techs(tech, order) do
    case third_party(order.id) do
      false -> AppCountCom.WorkOrders.order_prioritized(tech.email, order, tech, order.property)
      _ -> nil
    end
  end

  def email_resident(admin_id, %{"notes" => notes, "order_id" => order_id}) do
    AppCount.Maintenance.Utils.Notes.create_note(%{
      order_id: order_id,
      text: notes,
      admin_id: admin_id,
      image: nil
    })

    admin =
      from(a in Admins.Admin, select: a.name, where: a.id == ^admin_id)
      |> Repo.one()

    {order, email, name, property} =
      from(
        o in Order,
        join: t in assoc(o, :tenant),
        join: p in assoc(o, :property),
        left_join: l in assoc(p, :logo_url),
        where: o.id == ^order_id,
        select: {
          o,
          t.email,
          fragment("? || ' ' || ?", t.first_name, t.last_name),
          merge(p, %{logo: l.url})
        }
      )
      |> Repo.one()

    case third_party(order_id) do
      false -> AppCountCom.WorkOrders.email_resident(order, email, name, admin, notes, property)
      _ -> nil
    end
  end

  def no_access(%ClientSchema{name: client_schema, attrs: tech_id}, id) do
    tech_name =
      from(t in Tech, where: t.id == ^tech_id, select: t.name)
      |> Repo.one(prefix: client_schema)

    attempts =
      from(
        o in Order,
        select: o.no_access,
        where: o.id == ^id
      )
      |> Repo.one(prefix: client_schema)

    new_value =
      [%{tech_id: tech_id, time: AppCount.current_time(), tech_name: tech_name}]
      |> Enum.concat(attempts || [])

    Repo.get(Order, id, prefix: client_schema)
    |> Order.changeset(%{no_access: new_value})
    |> Repo.update!(prefix: client_schema)
  end

  ## USE THE BELOW FUNCTIONS TO GET A SNAPSHOT OF A SPREAD OF TIME
  def daily_snapshot(property_id, start_date, end_date) do
    start_day = Timex.beginning_of_day(start_date)
    end_day = Timex.end_of_day(end_date)
    created = orders_created(property_id, start_day, end_day)
    completed = orders_completed(property_id, start_day, end_day)
    property = Repo.get(AppCount.Properties.Property, property_id)

    %{
      name: property.name,
      id: property.id,
      created: created,
      completed: completed
    }
  end

  def daily_snapshot(property_id, date) do
    created = orders_created(property_id, date)
    completed = orders_completed(property_id, date)

    property =
      Repo.get(AppCount.Properties.Property, property_id)
      |> Repo.preload(:icon_url)

    %{
      icon: (property.icon_url || %{url: nil}).url,
      name: property.name,
      id: property.id,
      created: created,
      completed: completed
    }
  end

  ## Three above functions are used together orders_completed/3, orders_created/3 and daily_snapshot/3

  ###########################################################
  ## Make this call to return a daily snapshot of a property.
  def admin_daily_snapshot(admin, date) do
    property_ids = Admins.property_ids_for(admin)

    Enum.map(property_ids, fn property_id ->
      property_id
      |> daily_snapshot(date)
    end)
  end

  def order_query_modular(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: property_ids
        },
        type
      ) do
    assignment_query =
      from(
        a in Assignment,
        left_join: t in assoc(a, :tech),
        left_join: admin in assoc(a, :admin),
        select: map(a, [:id, :status, :order_id, :completed_at, :inserted_at]),
        select_merge: %{
          tech: t.name,
          admin: admin.name
        }
      )

    from(
      wo in Order,
      left_join: a in subquery(assignment_query),
      on: a.order_id == wo.id,
      left_join: u in assoc(wo, :unit),
      left_join: p in assoc(wo, :property),
      where: wo.property_id in ^property_ids,
      where: is_nil(wo.cancellation),
      having:
        fragment("(array_agg(? ORDER BY ? DESC))[1] = ANY(?)", a.status, a.inserted_at, [^type]),
      order_by: [
        asc: wo.inserted_at
      ],
      select: %{
        id: wo.id,
        unit: %{
          id: u.id,
          number: u.number
        },
        property: %{
          id: p.id,
          name: p.name
        },
        assignments: jsonize(a, [:id, :status])
      },
      group_by: [p.id, u.id, wo.id, a.id]
    )
    |> Repo.all(prefix: client_schema)
  end

  def open_order_query(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      wo in Order,
      left_join: a in assoc(wo, :assignments),
      left_join: u in assoc(wo, :unit),
      left_join: p in assoc(u, :property),
      join: sc in assoc(wo, :category),
      join: c in assoc(sc, :parent),
      where: wo.property_id in ^property_ids,
      where: is_nil(wo.cancellation),
      where: c.name != "Make Ready",
      having:
        fragment(
          "(array_agg(? ORDER BY ? DESC))[1] = ANY(?) OR count(?) = 0",
          a.status,
          a.inserted_at,
          ["withdrawn", "revoked", "rejected", "canceled", "callback", "on_hold", "in_progress"],
          a.id
        ),
      order_by: [
        asc: wo.inserted_at
      ],
      select: %{
        id: wo.id,
        unit_id: u.id,
        number: u.number,
        property_id: p.id,
        property: p.name,
        category: fragment("? || ' ' || ?", c.name, sc.name)
      },
      group_by: [p.id, u.id, wo.id, c.name, sc.name]
    )
    |> Repo.all(prefix: client_schema)
  end

  defp currently_open(admin) do
    property_ids = admin.property_ids
    client_schema = admin.client_schema

    reg_count =
      ClientSchema.new(client_schema, property_ids)
      |> open_order_query()
      |> length()

    vendors_count =
      ClientSchema.new(client_schema, property_ids)
      |> AppCount.Vendors.OrderRepo.currently_open()
      |> length()

    reg_count + vendors_count
  end

  ## Expects an id and date and will return a number of orders created
  defp orders_created(property_id, date) do
    from(
      o in Order,
      join: c in assoc(o, :category),
      select: count(o.id),
      join: p in assoc(o, :property),
      where: p.id == ^property_id,
      where:
        o.inserted_at > ^Timex.beginning_of_day(date) and o.inserted_at < ^Timex.end_of_day(date) and
          not c.third_party
    )
    |> Repo.one()
  end

  defp orders_created(property_id, start_date, end_date) do
    from(
      o in Order,
      join: c in assoc(o, :category),
      select: o.id,
      join: u in assoc(o, :unit),
      join: p in assoc(u, :property),
      where:
        o.inserted_at > ^start_date and o.inserted_at < ^end_date and p.id == ^property_id and
          not c.third_party
    )
    |> Repo.all()
    |> length
  end

  ## Expects an ID and date and will return a number with callbacks and completed
  defp orders_completed(property_id, date) do
    from(
      a in Assignment,
      join: o in assoc(a, :order),
      join: p in assoc(o, :property),
      join: c in assoc(o, :category),
      select: count(o.id),
      where: p.id == ^property_id and a.status == "completed" and not c.third_party,
      where:
        a.completed_at > ^Timex.beginning_of_day(date) and
          a.completed_at < ^Timex.end_of_day(date)
    )
    |> Repo.one()
  end

  defp orders_completed(property_id, start_date, end_date) do
    from(
      a in Assignment,
      join: o in assoc(a, :order),
      join: u in assoc(o, :unit),
      join: p in assoc(u, :property),
      join: c in assoc(o, :category),
      select: %{
        callbacks: count_by(a.status, "callback"),
        completed: count_by(a.status, "completed")
      },
      group_by: p.id,
      where:
        p.id == ^property_id and a.completed_at > ^start_date and a.completed_at < ^end_date and
          not c.third_party
    )
    |> Repo.all()
  end

  def info_for_daily_report(admin) do
    today =
      AppCount.current_time()
      |> Timex.end_of_day()

    property_ids = admin.property_ids

    completed = Enum.reduce(property_ids, 0, fn id, sum -> sum + orders_completed(id, today) end)
    created = Enum.reduce(property_ids, 0, fn id, sum -> sum + orders_created(id, today) end)
    open = currently_open(admin)
    not_ready_units = AppCount.Maintenance.Utils.Cards.not_ready_units(admin)
    make_readies_completed = make_readies_completed(admin, today)
    techs = AppCount.Maintenance.Utils.Techs.get_active_techs(ClientSchema.new(admin), today)
    admins = AppCount.Admins.Utils.Admins.list_admins(ClientSchema.new(admin))

    %{
      completed: completed,
      created: created,
      open: open,
      not_ready_units: not_ready_units,
      make_readies_completed: make_readies_completed,
      techs: techs,
      admins: admins
    }
  end

  defp make_readies_completed(admin, date) do
    property_ids = admin.property_ids

    from(
      i in CardItem,
      join: c in assoc(i, :card),
      join: u in assoc(c, :unit),
      join: p in assoc(u, :property),
      select: %{
        id: u.id,
        number: u.number,
        property: p.name,
        property_id: p.id
      },
      where: i.completed == ^Timex.to_date(date),
      where: i.name == "Final Inspection",
      where: p.id in ^property_ids,
      where: not is_nil(i.completed)
    )
    |> Repo.all()
  end

  def delete_order(id) do
    Repo.get(Order, id)
    |> Repo.delete()
  end

  def send_daily_snapshot do
    wday =
      AppCount.current_time()
      |> Timex.weekday()

    if wday in [1, 2, 3, 4, 5] do
      Repo.all(AppCount.Admins.Admin)
      |> Enum.each(fn admin ->
        date = AppCount.current_time()
        properties = admin_daily_snapshot(admin, date)
        AppCountCom.WorkOrders.daily_snapshot(admin, date, properties)
      end)
    end
  end

  defp assign_ticket(%{id: id, uuid: uuid} = order) do
    ticket =
      :crypto.hash(:md5, "#{id}")
      |> Base.encode16()
      |> String.slice(22, 10)

    new_uuid =
      case uuid do
        nil -> UUID.uuid4()
        _ -> uuid
      end

    order
    |> Order.changeset(%{ticket: ticket, uuid: new_uuid})
    |> Repo.update!()
  end

  defp assign_status(pass_through, order_id, status) do
    AppCount.Core.Tasker.start(__MODULE__, :assign_status_task, [order_id, status])

    pass_through
  end

  # UNTESTED
  def assign_status_task(order_id, status) do
    Repo.get(Order, order_id)
    |> Order.changeset(%{status: status})
    |> Repo.update()

    :ok
  end

  def third_party(order_id) do
    from(
      o in Order,
      join: c in assoc(o, :category),
      where: o.id == ^order_id,
      select: c.third_party,
      limit: 1
    )
    |> Repo.one()
  end

  def assign_uuids() do
    from(
      o in Order,
      where: is_nil(o.uuid),
      select: o
    )
    |> Repo.all()
    |> Enum.each(&assign_ticket(&1))
  end
end
