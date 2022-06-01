defmodule AppCount.Admins.Utils.OrgCharts do
  alias AppCount.Admins.OrgChart
  alias AppCount.Repo
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def get_parent(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin_id
      }) do
    # TODO:SCHEMA Parent_id needs to be looked at
    pid =
      Repo.get_by(OrgChart, [admin_id: admin_id], prefix: client_schema)
      |> case do
        nil -> nil
        oc -> OrgChart.parent_id(oc)
      end

    case pid do
      nil ->
        nil

      _ ->
        from(
          o in OrgChart,
          join: a in assoc(o, :admin),
          where: o.id == ^pid,
          select: %{
            id: a.id,
            name: a.name,
            email: a.email
          },
          limit: 1
        )
        |> Repo.one(prefix: client_schema)
    end
  end

  def is_parent(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: approver_id
        },
        requester_id
      ) do
    get_admin(%AppCount.Core.ClientSchema{
      name: client_schema,
      attrs: approver_id
    })
    |> OrgChart.descendants()
    |> Repo.all(prefix: client_schema)
    |> Stream.map(fn x -> x.id end)
    |> Enum.member?(requester_id)
  end

  def find_depth(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin_id
      }) do
    get_admin(ClientSchema.new(client_schema, admin_id))
    |> OrgChart.path_ids()
  end

  def create_root(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    Repo.insert(OrgChart.changeset(%OrgChart{}, params), prefix: client_schema)
  end

  def make_child(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: child_id
        },
        nil
      ) do
    case Repo.get_by(OrgChart, [admin_id: child_id], prefix: client_schema) do
      nil -> OrgChart.changeset(%OrgChart{}, %{admin_id: child_id})
      admin -> OrgChart.changeset(admin, %{admin_id: admin.admin_id, path: []})
    end
  end

  def make_child(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: child_id
        },
        parent_id
      ) do
    parent = get_admin(ClientSchema.new(client_schema, parent_id))

    case Repo.get_by(OrgChart, [admin_id: child_id], prefix: client_schema) do
      nil ->
        OrgChart.changeset(%OrgChart{}, %{admin_id: child_id})

      admin ->
        %{admin | admin_id: admin.admin_id}
    end
    # TODO:SCHEMA need fix
    |> OrgChart.make_child_of(parent)
  end

  def update(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %{"tree" => tree, "parent" => parent}
      }) do
    extract_nodes(
      %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: parent
      },
      tree
    )
  end

  def extract_nodes(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: prev_node
        },
        node
      ) do
    Repo.insert_or_update(
      make_child(ClientSchema.new(client_schema, node["admin_id"]), prev_node["admin_id"] || nil)
    )

    if length(node["children"]) > 0 do
      Enum.each(node["children"], fn child ->
        extract_nodes(
          ClientSchema.new(client_schema, node),
          child
        )
      end)
    end
  end

  def ancestors(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin_id
      }) do
    get_admin(ClientSchema.new(client_schema, admin_id))
    |> OrgChart.ancestors()
  end

  def children(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin_id
      }) do
    get_admin(ClientSchema.new(client_schema, admin_id))
    |> OrgChart.descendants()
  end

  def admin_query(query) do
    query
    |> join(:inner, [oc], admin in assoc(oc, :admin))
    |> select(
      [ad, admin],
      %{
        admin_id: ad.admin_id,
        path: ad.path,
        id: ad.id,
        name: admin.name
      }
    )
  end

  # To be used in mentions so that the user can mention anyone that is in the org chart
  def get_everyone(%AppCount.Core.ClientSchema{
        name: client_schema
      }) do
    from(
      c in OrgChart,
      join: a in assoc(c, :admin),
      select: %{
        id: c.admin_id,
        name: a.name,
        email: a.email
      },
      order_by: [asc: a.name]
    )
    |> Repo.all(prefix: client_schema)
  end

  def index(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin_id
      }) do
    children =
      from(
        chart in OrgChart,
        join: admin in assoc(chart, :admin),
        select: %{
          admin_id: chart.admin_id,
          name: admin.name,
          email: admin.email,
          id: chart.id,
          path: chart.path
        }
      )
      |> Repo.all(prefix: client_schema)
      |> OrgChart.arrange()
      |> nested_tuple_to_list()

    %{
      tree: children,
      admin_list:
        unauthorized_admin_list(%AppCount.Core.ClientSchema{
          name: client_schema
        }),
      current_user:
        from(n in OrgChart, where: n.admin_id == ^admin_id)
        |> admin_query
        |> Repo.one(prefix: client_schema)
    }
  end

  def unauthorized_admin_list(%AppCount.Core.ClientSchema{
        name: client_schema
      }) do
    #    get a list of all admins that are not in admin permissions table
    from(
      admin in AppCount.Admins.Admin,
      left_join: oc in OrgChart,
      on: admin.id == oc.admin_id,
      where: is_nil(oc),
      order_by: [admin.name],
      select: %{
        children: [],
        name: admin.name,
        admin_id: admin.id,
        email: admin.email
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_admin(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    Repo.get_by!(OrgChart, [admin_id: id], prefix: client_schema)
  end

  def descendants(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      }) do
    if MapSet.member?(admin.roles, "Super Admin") do
      from(
        c in OrgChart,
        join: a in assoc(c, :admin),
        select: %{
          id: c.id,
          admin_id: c.admin_id,
          admin_name: a.name,
          status: c.status,
          email: a.email
        },
        order_by: [asc: a.name]
      )
      |> Repo.all(prefix: client_schema)
    else
      get_admin(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin.id
      })
      # TODO:SCHEMA OrgChart.descendants need schema fix
      |> OrgChart.descendants()
      |> join(:inner, [o], a in AppCount.Admins.Admin, on: a.id == o.admin_id)
      |> select([o, a], %{id: o.id, admin_id: o.admin_id, admin_name: a.name, status: o.status})
      |> order_by([o, a], asc: a.name)
      |> Repo.all(prefix: client_schema)
    end
  end

  defp nested_tuple_to_list(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.map(&nested_tuple_to_list/1)
  end

  defp nested_tuple_to_list(list) when is_list(list) do
    list
    |> Enum.map(&nested_tuple_to_list/1)
  end

  defp nested_tuple_to_list(x), do: x

  def delete(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    admin = Repo.get(OrgChart, id, prefix: client_schema)
    # TODO:SCHEMA schema check
    OrgChart.descendants(admin)
    |> Repo.all(prefix: client_schema)
    |> Enum.each(fn %{path: path} = admin ->
      OrgChart.changeset(admin, %{path: List.delete(path, String.to_integer(id))})
      |> Repo.update(prefix: client_schema)
    end)

    Repo.delete(admin, prefix: client_schema)
  end
end
