defmodule AppCount.Maintenance.Utils.Queries.ShowOrder do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Note
  alias AppCount.Core.ClientSchema

  def show_order(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, id) do
    property_ids = Admins.property_ids_for(ClientSchema.new(client_schema, admin))

    from(
      o in Order,
      join: p in assoc(o, :property),
      join: c in assoc(o, :category),
      join: pc in assoc(c, :parent),
      left_join: t in assoc(o, :tenant),
      left_join: u in assoc(o, :unit),
      left_join: parts in assoc(o, :parts),
      left_join: fp in assoc(u, :floor_plan),
      left_join: a in subquery(assignment_query()),
      on: a.order_id == o.id,
      left_join: n in subquery(notes_query()),
      on: n.order_id == o.id,
      left_join: at in subquery(attachments_query()),
      on: at.order_id == o.id,
      where: o.property_id in ^property_ids and o.id == ^id,
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
          :property_id,
          :allow_sms
        ]),
      select_merge: %{
        property: map(p, [:id, :name, :lat, :lng]),
        tenant: map(t, [:id, :first_name, :last_name, :email, :alarm_code, :phone]),
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
        parts: jsonize(parts, [:id, :name, :status, :order_id, :updated_at]),
        assignments: a.assignments,
        attachments: at.attachments,
        notes: n.notes
      },
      group_by: [
        o.id,
        p.id,
        t.id,
        c.id,
        pc.id,
        u.id,
        fp.name,
        a.assignments,
        n.notes,
        at.attachments
      ],
      limit: 1
    )
    |> Repo.one(prefix: client_schema)
    |> get_extra_info()
  end

  defp get_extra_info(nil), do: nil

  defp get_extra_info(order) do
    # unit_status =
    #   case unit_status(order.unit.id, order.property_id) do
    #     nil -> nil
    #     status -> Map.merge(order.unit, %{status: status.status})
    #   end

    order_status = get_status(order)
    Map.merge(order, order_status)
    # Map.merge(order, %{unit: unit_status})
    # |> Map.merge(order_status)
  end

  defp get_status(%{cancellation: c}) when not is_nil(c), do: %{status: "cancelled"}

  defp get_status(%{card: c}) when not is_nil(c) do
    case List.first(c)["completed"] do
      nil -> "unassigned"
      _ -> "completed"
    end
  end

  #  defp get_status(%{assignments: []}), do: %{status: "unassigned"}
  defp get_status(%{assignments: a}) when is_nil(a), do: %{status: "unassigned"}

  defp get_status(%{assignments: a}) do
    key = %{
      "withdrawn" => "unassigned",
      "callback" => "unassigned",
      "rejected" => "unassigned",
      "on_hold" => "assigned",
      "in_progress" => "assigned"
    }

    status = List.first(a)["status"]
    %{status: Map.get(key, status, status), callback: status == "callback"}
  end

  defp assignment_query() do
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
              :resident_comment,
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

  defp attachments_query() do
    from(
      n in Note,
      left_join: t in assoc(n, :tech),
      left_join: a in assoc(n, :admin),
      left_join: ten in assoc(n, :tenant),
      left_join: at in assoc(n, :attachment),
      left_join: url in assoc(n, :attachment_url),
      where: not is_nil(n.attachment_id),
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

  defp notes_query() do
    from(
      n in Note,
      left_join: t in assoc(n, :tech),
      left_join: a in assoc(n, :admin),
      left_join: ten in assoc(n, :tenant),
      where: is_nil(n.attachment_id),
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
end
