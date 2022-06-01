defmodule AppCount.Maintenance.Utils.Public.Orders do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Note
  alias AppCount.Core.ClientSchema

  def get_order(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: uuid
        },
        nil
      ) do
    from(
      o in Order,
      join: p in assoc(o, :property),
      left_join: l in assoc(p, :logo_url),
      left_join: i in assoc(p, :icon_url),
      join: c in assoc(o, :category),
      join: pc in assoc(c, :parent),
      left_join: t in assoc(o, :tenant),
      left_join: u in assoc(o, :unit),
      left_join: fp in assoc(u, :floor_plan),
      left_join: a in subquery(assignment_query()),
      on: a.order_id == o.id,
      left_join: n in subquery(notes_query()),
      on: n.order_id == o.id,
      left_join: at in subquery(attachments_query()),
      on: at.order_id == o.id,
      where: o.uuid == ^uuid,
      select:
        map(o, [
          :id,
          :inserted_at,
          :has_pet,
          :entry_allowed,
          :priority,
          :no_access,
          :ticket,
          :cancellation,
          :created_by,
          :property_id
        ]),
      select_merge: %{
        #        property: map(p, [:id, :name, :lat, :lng, :phone, :website]),
        tenant: map(t, [:id, :first_name, :last_name, :email, :alarm_code]),
        property: %{
          id: p.id,
          name: p.name,
          lat: p.lat,
          lng: p.lng,
          phone: p.phone,
          website: p.website,
          logo: l.url
        },
        unit: %{
          id: u.id,
          number: u.number,
          area: u.area,
          floor_plan: fp.name
        },
        category: %{
          id: c.id,
          parent_id: pc.id,
          category: c.name,
          parent_name: pc.name
        },
        assignments: a.assignments,
        attachments: at.attachments,
        notes: n.notes,
        type: "maintenance"
      },
      group_by: [
        o.id,
        p.id,
        t.id,
        c.id,
        pc.id,
        u.id,
        fp.name,
        l.url,
        a.assignments,
        n.notes,
        at.attachments
      ],
      limit: 1
    )
    |> Repo.one(prefix: client_schema)
    |> get_extra_info()
  end

  def get_order(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: uuid
        },
        :rate
      ) do
    from(
      o in Order,
      left_join: a in assoc(o, :assignments),
      join: c in assoc(o, :category),
      join: p in assoc(c, :parent),
      where: o.uuid == ^uuid,
      preload: [assignments: a, category: {c, parent: p}]
    )
    |> Repo.one(prefix: client_schema)
  end

  defp get_extra_info(nil), do: nil

  defp get_extra_info(order) do
    order_status = get_status(order)
    Map.merge(order, order_status)
  end

  def get_status(%{cancellation: c}) when not is_nil(c), do: "cancelled"

  def get_status(%{card: c}) when not is_nil(c) do
    case List.first(c)["completed"] do
      nil -> "unassigned"
      _ -> "completed"
    end
  end

  def get_status(%{assignments: []}), do: %{status: "unassigned"}
  def get_status(%{assignments: a}) when is_nil(a), do: %{status: "unassigned"}

  def get_status(%{assignments: a}) do
    case List.first(a)["status"] do
      "withdrawn" -> %{status: "unassigned"}
      "callback" -> %{status: "unassigned", callback: true}
      "rejected" -> %{status: "unassigned"}
      "on_hold" -> %{status: "assigned"}
      "in_progress" -> %{status: "assigned"}
      s -> %{status: s}
    end
  end

  def assignment_query() do
    from(
      a in Assignment,
      left_join: t in assoc(a, :tech),
      left_join: ad in assoc(a, :admin),
      left_join: p in assoc(a, :payee),
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

  def attachments_query() do
    from(
      n in Note,
      left_join: t in assoc(n, :tech),
      left_join: a in assoc(n, :admin),
      left_join: ten in assoc(n, :tenant),
      left_join: at in assoc(n, :attachment),
      left_join: url in assoc(n, :attachment_url),
      where: not is_nil(n.attachment_id) and (n.visible_to_resident or not is_nil(n.tenant_id)),
      select: %{
        order_id: n.order_id,
        attachments:
          type(
            jsonize(
              n,
              [
                :id,
                {:content_type, at.content_type},
                {:url, url.url},
                :inserted_at,
                {:type,
                 fragment(
                   "CASE
            WHEN ? IS NOT NULL THEN 'tech'
            WHEN ? IS NOT NULL THEN 'admin'
            WHEN ? IS NOT NULL THEN 'resident'
            else 'auto'
          END",
                   n.tech_id,
                   n.admin_id,
                   n.tenant_id
                 )},
                {:creator,
                 fragment(
                   "CASE
            WHEN ? IS NOT NULL THEN ?
            WHEN ? IS NOT NULL THEN ?
            WHEN ? IS NOT NULL THEN ?
            else 'auto'
          END",
                   n.tech_id,
                   t.name,
                   n.admin_id,
                   a.name,
                   n.tenant_id,
                   fragment("? || ' ' || ?", ten.first_name, ten.last_name)
                 )}
              ]
            ),
            AppCount.Data.Uploads
          )
      },
      group_by: [n.order_id]
    )
  end

  def notes_query() do
    from(
      n in Note,
      left_join: t in assoc(n, :tech),
      left_join: a in assoc(n, :admin),
      left_join: ten in assoc(n, :tenant),
      where: is_nil(n.attachment_id) and (n.visible_to_resident or not is_nil(n.tenant_id)),
      select: %{
        order_id: n.order_id,
        notes:
          jsonize(n, [
            :id,
            :text,
            :inserted_at,
            :image,
            {:creator,
             fragment(
               "CASE
              WHEN ? IS NOT NULL THEN ?
              WHEN ? IS NOT NULL THEN ?
              WHEN ? IS NOT NULL THEN ?
              else 'auto'
            END",
               n.tech_id,
               t.name,
               n.admin_id,
               a.name,
               n.tenant_id,
               fragment("? || ' ' || ?", ten.first_name, ten.last_name)
             )},
            {:type,
             fragment(
               "CASE
              WHEN ? IS NOT NULL THEN 'tech'
              WHEN ? IS NOT NULL THEN 'admin'
              WHEN ? IS NOT NULL THEN 'resident'
              else 'auto'
            END",
               n.tech_id,
               n.admin_id,
               n.tenant_id
             )}
          ])
      },
      group_by: [n.order_id]
    )
  end

  def update_assignment(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: id
        },
        params
      ) do
    Repo.get(Assignment, id, prefix: client_schema)
    |> Assignment.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def public_rate_token(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: order_id
        },
        token_fn
      ) do
    order =
      Repo.get(Order, order_id, prefix: client_schema)
      |> Repo.preload(:assignments)

    cond do
      is_nil(order.uuid) -> generate_uuid(order, token_fn)
      true -> token_fn.(%{uuid: order.uuid})
    end
  end

  defp generate_uuid(
         %AppCount.Core.ClientSchema{
           name: client_schema,
           attrs: order
         },
         token_fn
       ) do
    order
    |> Order.changeset(%{uuid: UUID.uuid4()})
    |> Repo.update!(prefix: client_schema)

    public_rate_token(ClientSchema.new(client_schema, order.id), token_fn)
  end
end
