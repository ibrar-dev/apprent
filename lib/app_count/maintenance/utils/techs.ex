defmodule AppCount.Maintenance.Utils.Techs do
  alias AppCountAuth.Users.Admin
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Category
  alias AppCount.Maintenance.Job
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.PresenceLog
  alias AppCount.Maintenance.Skill
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.TechRepo
  alias AppCount.Maintenance.Utils.Reports
  alias AppCount.Materials.Utils.ToolboxItems
  alias AppCount.Repo
  alias Ecto.Multi
  alias AppCount.Core.ClientSchema

  import AppCount.EctoExtensions
  import Ecto.Query

  require Logger

  def endpoint do
    # It would be better to handle this with events
    Module.concat(["AppCountWeb.Endpoint"])
  end

  @doc """
  Given an admin and properties available to that admin, returns all active
  techs for those properties.

  Result is a list of maps like this:

  %{
    id: 123,
    name: "David S. Pumpkins",
    property_ids: [13, 45, 58]
  }
  """
  def list_techs(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        :min
      ) do
    from(
      t in Tech,
      left_join: j in assoc(t, :jobs),
      where: j.property_id in ^admin.property_ids and t.active == true,
      select: %{
        id: t.id,
        name: t.name,
        property_ids: fragment("ARRAY_AGG(distinct ?)", j.property_id)
      },
      group_by: t.id
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_techs(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: %Admin{roles: roles} = admin
        },
        :tech
      ) do
    if "Super Admin" in roles do
      list_techs(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        :tech,
        :super_admin
      )
    else
      list_techs(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        :tech,
        :regular_admin
      )
    end
  end

  def list_techs(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        :loc
      ) do
    techs =
      from(
        t in Tech,
        join: j in assoc(t, :jobs),
        where: j.property_id in ^admin.property_ids,
        select: %{
          id: t.id,
          name: t.name,
          image: t.image
        }
      )
      |> Repo.all(prefix: client_schema)

    locations = Agent.get(:tech_tracking, & &1)
    presence = AppCountWeb.TechPresence.list("tech_admin")

    Enum.map(
      techs,
      fn tech ->
        loc = locations[tech.id] || %{lat: nil, lng: nil}
        presence = !!presence["#{client_schema}-#{tech.id}"]

        tech
        |> Map.merge(loc)
        |> Map.merge(%{presence: presence})
      end
    )
  end

  def list_techs(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        :assign
      ) do
    stats = Reports.tech_stats_query()
    month_stats = Reports.month_stats_query()

    category_query =
      from(
        s in Skill,
        select: %{
          tech_id: s.tech_id,
          category_ids: array(s.category_id)
        },
        group_by: s.tech_id
      )

    open_query =
      from(
        a in Assignment,
        join: o in assoc(a, :order),
        where: a.status in ["on_hold", "in_progress"] and o.status == "assigned",
        select: %{
          open: count(a.id),
          tech_id: a.tech_id
        },
        group_by: [a.tech_id]
      )

    from(
      t in Tech,
      left_join: j in assoc(t, :jobs),
      left_join: s in subquery(category_query),
      on: s.tech_id == t.id,
      left_join: st in subquery(stats),
      on: st.tech_id == t.id,
      left_join: mst in subquery(month_stats),
      on: mst.tech_id == t.id,
      left_join: as in subquery(open_query),
      on: as.tech_id == t.id,
      where: j.property_id in ^admin.property_ids,
      where: t.active,
      order_by: [
        asc: t.name
      ],
      select:
        map(t, [
          :id,
          :name,
          :email,
          :type,
          :phone_number,
          :image
        ]),
      select_merge: %{
        property_ids: array(j.property_id),
        category_ids: s.category_ids,
        stats: jsonize_one(st, [:rating, :completion_time, :callbacks, :completed]),
        month_stats: jsonize_one(mst, [:rating, :completion_time]),
        assignments: as.open
      },
      group_by: [t.id, s.category_ids, as.open]
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_techs(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: %Admin{} = _admin
        },
        :tech,
        :super_admin
      ) do
    techs =
      tech_tech_query(:super_admin)
      |> Repo.all(prefix: client_schema)

    locations = Agent.get(:tech_tracking, & &1)
    # FIX_DEPS
    presence = AppCountWeb.TechPresence.list("tech_admin")

    Enum.map(
      techs,
      fn tech ->
        loc = locations[tech.id] || %{lat: nil, lng: nil}
        presence = !!presence["#{tech.id}"]

        tech
        |> Map.merge(loc)
        |> Map.merge(%{presence: presence})
      end
    )
  end

  def list_techs(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: %{} = admin
        },
        :tech,
        :regular_admin
      ) do
    techs =
      admin.property_ids
      |> tech_tech_query
      |> Repo.all(prefix: client_schema)

    locations = Agent.get(:tech_tracking, & &1)
    # FIX_DEPS
    presence = AppCountWeb.TechPresence.list("tech_admin")

    Enum.map(
      techs,
      fn tech ->
        loc = locations[tech.id] || %{lat: nil, lng: nil}
        presence = !!presence["#{tech.id}"]

        tech
        |> Map.merge(loc)
        |> Map.merge(%{presence: presence})
      end
    )
  end

  def list_techs(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      }) do
    techs =
      admin.property_ids
      |> tech_query
      |> Repo.all(prefix: client_schema)

    locations = Agent.get(:tech_tracking, & &1)
    presence = AppCountWeb.TechPresence.list("tech_admin")

    Enum.map(
      techs,
      fn tech ->
        loc = locations[tech.id] || %{lat: nil, lng: nil}
        presence = !!presence["#{tech.id}"]

        tech
        |> Map.merge(loc)
        |> Map.merge(%{presence: presence})
      end
    )
  end

  def tech_details(%AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    from(
      t in Tech,
      join: a in assoc(t, :assignments),
      where: t.id == ^id and a.status in ["completed", "callback"],
      select: %{
        rating: avg(a.rating),
        completion_time: fragment("avg(? - ?)", a.completed_at, a.confirmed_at)
      }
    )
    |> Repo.one(prefix: client_schema)
  end

  def create_tech(params) do
    result = TechRepo.insert(params)

    case result do
      {:ok, _} ->
        set_tech_jobs(result, ClientSchema.new("dasmen", params))

      {:error, changeset} ->
        changeset
        |> inspect()
        |> Logger.error()

        {:error, changeset}
    end
  end

  def update_tech(%ClientSchema{name: client_schema, attrs: id}, params) do
    Repo.get(Tech, id, prefix: client_schema)
    |> TechRepo.update(params, prefix: client_schema)
    |> set_tech_jobs(%ClientSchema{name: client_schema, attrs: params})
  end

  def delete_tech(id) do
    Repo.get(Tech, id)
    |> Repo.delete()
  end

  def set_tech_coords(%ClientSchema{name: _client_schema, attrs: tech_id}, coords) do
    Agent.update(:tech_tracking, fn state -> Map.merge(state, %{tech_id => coords}) end)
    msg = Map.merge(%{tech_id: tech_id}, coords)
    # TODO need to make this client specific
    endpoint().broadcast("tech_admin", "COORDINATES", %{msg: msg})
  end

  def set_pass_code(%Tech{} = tech) do
    tech =
      tech
      |> TechRepo.update!(%{pass_code: UUID.uuid4()})

    ClientSchema.new("dasmen", tech)
    |> send_to_tech
  end

  def set_pass_code(tech_id), do: set_pass_code(Repo.get(Tech, tech_id))

  def tech_detailed_info(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: tech_id
      }) do
    stats = Reports.tech_stats_query()
    toolbox = ToolboxItems.list_all_items()

    category_query =
      from(
        s in Skill,
        select: %{
          tech_id: s.tech_id,
          category_ids: array(s.category_id)
        },
        group_by: s.tech_id,
        where: s.tech_id == ^tech_id
      )

    assignment_query =
      from(
        a in Assignment,
        select: %{
          id: a.id,
          status: a.status,
          tech_id: a.tech_id,
          inserted_at: a.inserted_at,
          updated_at: a.updated_at,
          completed_at: a.completed_at,
          rating: a.rating,
          tech_comments: a.tech_comments,
          order_id: a.order_id,
          confirmed_at: a.confirmed_at
        },
        where: a.tech_id == ^tech_id
      )

    order_query =
      from(
        o in Order,
        left_join: t in assoc(o, :tenant),
        left_join: p in assoc(o, :property),
        left_join: c in assoc(o, :category),
        left_join: u in assoc(o, :unit),
        select: %{
          id: o.id,
          tenant: fragment("? || ' ' || ?", t.first_name, t.last_name),
          property: p.name,
          submitted: o.inserted_at,
          category: c.name,
          unit: u.number
        }
      )

    from(
      t in Tech,
      left_join: a in subquery(assignment_query),
      on: a.tech_id == t.id,
      left_join: s in subquery(category_query),
      on: s.tech_id == t.id,
      left_join: st in subquery(stats),
      on: st.tech_id == t.id,
      left_join: tb in subquery(toolbox),
      on: tb.tech_id == t.id,
      left_join: o in subquery(order_query),
      on: a.order_id == o.id,
      select:
        map(t, [
          :id,
          :name,
          :email,
          :type,
          :description,
          :phone_number,
          :image,
          :pass_code,
          :can_edit,
          :active
        ]),
      select_merge: %{
        category_ids:
          fragment("CASE WHEN ? IS NULL THEN '{}' ELSE ? END", s.category_ids, s.category_ids),
        assignments:
          jsonize(a, [
            :id,
            :status,
            :order_id,
            :rating,
            :completed_at,
            :inserted_at,
            :updated_at,
            :confirmed_at,
            {:order, o}
          ]),
        stats: jsonize_one(st, [:rating, :completion_time, :callbacks, :completed]),
        toolbox:
          jsonize(
            tb,
            [
              :id,
              :stock,
              :stock_id,
              :material,
              :material_id,
              :admin,
              :status,
              :history,
              :cost,
              :per_unit,
              :inserted_at,
              :tech_id
            ]
          )
      },
      group_by: [t.id, s.category_ids],
      where: t.id == ^tech_id
    )
    |> Repo.one(prefix: client_schema)
  end

  def tech_info(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: tech_id
      }) do
    from(
      t in Tech,
      where: t.id == ^tech_id,
      select: %{
        id: t.id,
        name: t.name,
        phone_number: t.phone_number,
        email: t.email,
        identifier: t.identifier,
        can_edit: t.can_edit,
        image: t.image,
        require_image: t.require_image
      }
    )
    |> Repo.one(prefix: client_schema)
    |> Map.merge(%{
      rating:
        tech_details(%AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: tech_id
        }).rating
    })
  end

  def tech_data(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: tech_id
      }) do
    assignments =
      t_query(Assignment, tech_id)
      |> Repo.all(prefix: client_schema)

    # offers =
    #   t_query(Offer, tech_id)
    #   |> Repo.all(prefix: client_schema)

    %{assignments: assignments}
  end

  def log_on(tech_id), do: log_presence(tech_id, true)

  def log_off(tech_id), do: log_presence(tech_id, false)

  defp last_presence_log(%AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: tech_id
       }) do
    from(
      l in PresenceLog,
      order_by: [
        desc: l.inserted_at
      ],
      where: l.tech_id == ^tech_id,
      limit: 1,
      select: %{
        id: l.id,
        age:
          fragment("EXTRACT(EPOCH FROM CURRENT_TIMESTAMP) - EXTRACT(EPOCH FROM ?)", l.inserted_at),
        present: l.present
      }
    )
    |> Repo.one(prefix: client_schema)
  end

  defp log_presence(
         %AppCount.Core.ClientSchema{
           name: client_schema,
           attrs: tech_id
         },
         present
       ) do
    case last_presence_log(%AppCount.Core.ClientSchema{
           name: client_schema,
           attrs: tech_id
         }) do
      %{present: p} when p == present ->
        nil

      %{id: id, age: age} when age < 10 ->
        try do
          Repo.get(PresenceLog, id, prefix: client_schema)
          |> Repo.delete(prefix: client_schema)
        rescue
          Ecto.StaleEntryError -> nil
        end

      _ ->
        %PresenceLog{}
        |> PresenceLog.changeset(%{present: present, tech_id: tech_id})
        |> Repo.insert(prefix: client_schema)
    end
  end

  defmacrop notes_url do
    env = AppCount.env()[:environment]
    base_url = "https://s3-us-east-2.amazonaws.com/appcount-maintenance/notes/#{env}/"
    "array_agg(json_object('{text, image}', ARRAY[?, '#{base_url}' || ? || '/' || ?]))"
  end

  def attachments_query() do
    from(
      n in AppCount.Maintenance.Note,
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

  def tech_order_data(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: tech_id
        },
        order_id
      ) do
    assignments_query =
      from(
        a in Assignment,
        join: t in assoc(a, :tech),
        order_by: [desc: :inserted_at],
        select: %{
          id: a.id,
          order_id: a.order_id,
          tech: t.name,
          tech_id: t.id,
          status: a.status,
          text: a.tech_comments,
          updated_at: a.updated_at
        }
      )

    from(
      order in Order,
      left_join: as in subquery(assignments_query),
      on: as.order_id == order.id,
      left_join: cat in assoc(order, :category),
      left_join: scat in assoc(cat, :parent),
      left_join: unit in assoc(order, :unit),
      left_join: prop in assoc(order, :property),
      left_join: tenant in assoc(order, :tenant),
      left_join: notes in assoc(order, :notes),
      left_join: at in subquery(attachments_query()),
      on: at.order_id == order.id,
      where: as.tech_id == ^tech_id,
      where: order.id == ^order_id,
      group_by: [
        order.id,
        scat.name,
        tenant.first_name,
        tenant.last_name,
        tenant.phone,
        cat.name,
        unit.number,
        prop.name,
        cat.third_party,
        at.attachments
      ],
      select: %{
        order_id: order.id,
        require_image: order.require_image,
        entry_allowed: order.entry_allowed,
        has_pet: order.has_pet,
        ticket: order.ticket,
        category: cat.name,
        third_party: cat.third_party,
        sub_category: scat.name,
        unit: unit.number,
        priority: order.priority,
        inserted_at: order.inserted_at,
        property: prop.name,
        tenant: fragment("? || ' ' || ?", tenant.first_name, tenant.last_name),
        tenant_phone: tenant.phone,
        notes:
          fragment(
            notes_url(),
            notes.text,
            notes.id,
            notes.image
          ),
        attachments: at.attachments,
        assignments: jsonize(as, [:id, :tech, :status, :text, :updated_at])
      },
      limit: 1
    )
    |> Repo.one(prefix: client_schema)
  end

  defp t_query(mod, tech_id) do
    assignments_query =
      from(
        a in Assignment,
        join: t in assoc(a, :tech),
        where: not is_nil(a.tech_comments),
        order_by: [desc: :inserted_at],
        select: %{
          id: a.id,
          order_id: a.order_id,
          tech: t.name,
          status: a.status,
          text: a.tech_comments,
          updated_at: a.updated_at
        }
      )

    from(
      v in mod,
      left_join: order in assoc(v, :order),
      left_join: as in subquery(assignments_query),
      on: as.order_id == order.id,
      left_join: cat in assoc(order, :category),
      left_join: scat in assoc(cat, :parent),
      left_join: unit in assoc(order, :unit),
      left_join: prop in assoc(order, :property),
      left_join: tenant in assoc(order, :tenant),
      left_join: notes in assoc(order, :notes),
      left_join: at in subquery(attachments_query()),
      on: at.order_id == order.id,
      where: v.tech_id == ^tech_id,
      group_by: [
        v.id,
        order.id,
        scat.name,
        tenant.first_name,
        tenant.last_name,
        tenant.phone,
        cat.name,
        unit.number,
        prop.name,
        cat.third_party,
        at.attachments
      ],
      select: %{
        id: v.id,
        order_id: order.id,
        require_image: order.require_image,
        entry_allowed: order.entry_allowed,
        has_pet: order.has_pet,
        ticket: order.ticket,
        category: cat.name,
        third_party: cat.third_party,
        sub_category: scat.name,
        unit: unit.number,
        priority: order.priority,
        inserted_at: order.inserted_at,
        property: prop.name,
        tenant: fragment("? || ' ' || ?", tenant.first_name, tenant.last_name),
        tenant_phone: tenant.phone,
        notes:
          fragment(
            notes_url(),
            notes.text,
            notes.id,
            notes.image
          ),
        attachments: at.attachments,
        assignments: jsonize(as, [:id, :tech, :status, :text, :updated_at])
      }
    )
    |> merge_status(mod)
  end

  defp merge_status(query, Assignment),
    do:
      from(
        v in query,
        where: v.status in ["on_hold", "in_progress"],
        select_merge: %{
          status: v.status,
          materials: v.materials
        }
      )

  #  defp merge_status(query, Offer), do: query

  def tech_tech_query(property_ids) when is_list(property_ids) do
    stats = Reports.tech_stats_query()
    month_stats = Reports.month_stats_query()

    category_query =
      from(
        s in Skill,
        select: %{
          tech_id: s.tech_id,
          category_ids: array(s.category_id)
        },
        group_by: s.tech_id
      )

    from(
      t in Tech,
      left_join: j in assoc(t, :jobs),
      left_join: s in subquery(category_query),
      on: s.tech_id == t.id,
      left_join: st in subquery(stats),
      on: st.tech_id == t.id,
      left_join: mst in subquery(month_stats),
      on: mst.tech_id == t.id,
      where: j.property_id in ^property_ids,
      order_by: [
        asc: t.name
      ],
      select:
        map(t, [
          :id,
          :name,
          :email,
          :type,
          :description,
          :phone_number,
          :image,
          :pass_code,
          :can_edit,
          :active,
          :require_image
        ]),
      select_merge: %{
        property_ids: array(j.property_id),
        category_ids:
          fragment("CASE WHEN ? IS NULL THEN '{}' ELSE ? END", s.category_ids, s.category_ids),
        stats: jsonize_one(st, [:rating, :completion_time, :callbacks, :completed]),
        month_stats: jsonize_one(mst, [:rating, :completion_time])
      },
      group_by: [t.id, s.category_ids]
    )
  end

  def tech_tech_query(:super_admin) do
    stats = Reports.tech_stats_query()
    month_stats = Reports.month_stats_query()

    category_query =
      from(
        s in Skill,
        select: %{
          tech_id: s.tech_id,
          category_ids: array(s.category_id)
        },
        group_by: s.tech_id
      )

    from(
      t in Tech,
      left_join: j in assoc(t, :jobs),
      left_join: s in subquery(category_query),
      on: s.tech_id == t.id,
      left_join: st in subquery(stats),
      on: st.tech_id == t.id,
      left_join: mst in subquery(month_stats),
      on: mst.tech_id == t.id,
      order_by: [
        asc: t.name
      ],
      select:
        map(t, [
          :id,
          :name,
          :email,
          :type,
          :description,
          :phone_number,
          :image,
          :pass_code,
          :can_edit,
          :active,
          :require_image
        ]),
      select_merge: %{
        property_ids: array(j.property_id),
        category_ids:
          fragment("CASE WHEN ? IS NULL THEN '{}' ELSE ? END", s.category_ids, s.category_ids),
        stats: jsonize_one(st, [:rating, :completion_time, :callbacks, :completed]),
        month_stats: jsonize_one(mst, [:rating, :completion_time])
      },
      group_by: [t.id, s.category_ids]
    )
  end

  def tech_query(property_ids) do
    stats = Reports.tech_stats_query()
    month_stats = Reports.month_stats_query()

    category_query =
      from(
        s in Skill,
        select: %{
          tech_id: s.tech_id,
          category_ids: array(s.category_id)
        },
        group_by: s.tech_id
      )

    assignment_query =
      from(
        a in Assignment,
        select: %{
          id: a.id,
          status: a.status,
          tech_id: a.tech_id,
          inserted_at: a.inserted_at,
          updated_at: a.updated_at,
          completed_at: a.completed_at,
          rating: a.rating,
          tech_comments: a.tech_comments,
          order_id: a.order_id
        },
        where: a.status not in ["withdrawn", "rejected", "revoked"]
      )

    from(
      t in Tech,
      left_join: j in assoc(t, :jobs),
      left_join: a in subquery(assignment_query),
      on: a.tech_id == t.id,
      left_join: s in subquery(category_query),
      on: s.tech_id == t.id,
      left_join: st in subquery(stats),
      on: st.tech_id == t.id,
      left_join: mst in subquery(month_stats),
      on: mst.tech_id == t.id,
      where: j.property_id in ^property_ids,
      order_by: [
        asc: t.name
      ],
      select:
        map(t, [
          :id,
          :name,
          :email,
          :type,
          :description,
          :phone_number,
          :image,
          :pass_code,
          :can_edit,
          :active,
          :require_image
        ]),
      select_merge: %{
        property_ids: array(j.property_id),
        category_ids:
          fragment("CASE WHEN ? IS NULL THEN '{}' ELSE ? END", s.category_ids, s.category_ids),
        assignments: jsonize(a, [:id, :status, :order_id, :rating, :completed_at, :inserted_at]),
        stats: jsonize_one(st, [:rating, :completion_time, :callbacks, :completed]),
        month_stats: jsonize_one(mst, [:rating, :completion_time])
      },
      group_by: [t.id, s.category_ids]
    )
  end

  def last_six_months(%AppCount.Core.ClientSchema{name: client_schema, attrs: tech_id}) do
    Enum.map(
      0..5,
      fn x ->
        date = Timex.shift(AppCount.current_time(), months: -x)
        completed_for_tech(ClientSchema.new(client_schema, tech_id), date)
      end
    )
  end

  def get_active_techs(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, date) do
    start_date = Timex.beginning_of_day(date)
    end_date = Timex.end_of_day(date)

    assignment_query =
      from(
        a in Assignment,
        where:
          between(a.updated_at, ^start_date, ^end_date) or
            (between(
               a.completed_at,
               ^start_date,
               ^end_date
             ) and a.status in ["completed", "withdrawn"]),
        select: %{
          id: a.id,
          tech_id: a.tech_id
        }
      )

    from(
      t in Tech,
      join: j in assoc(t, :jobs),
      join: a in subquery(assignment_query),
      on: a.tech_id == t.id,
      where: j.property_id in ^admin.property_ids,
      select: %{
        id: t.id,
        name: t.name
      },
      distinct: t.id,
      group_by: [t.id, a.id]
    )
    |> Repo.all(prefix: client_schema)
  end

  defp completed_for_tech(
         %AppCount.Core.ClientSchema{name: client_schema, attrs: tech_id},
         start_date,
         end_date \\ nil
       ) do
    start_current_month = Timex.beginning_of_month(start_date)
    end_current_month = Timex.end_of_month(end_date || start_date)

    completed_query =
      from(
        a in Assignment,
        where:
          a.tech_id == ^tech_id and a.status == "completed" and
            (a.completed_at >= ^start_current_month and a.completed_at <= ^end_current_month),
        select: %{
          id: a.id,
          tech_id: a.tech_id,
          rating: a.rating
        }
      )

    callback_query =
      from(
        a in Assignment,
        where:
          a.tech_id == ^tech_id and a.status == "callback" and
            (a.completed_at >= ^start_current_month and a.completed_at <= ^end_current_month),
        select: %{
          id: a.id,
          tech_id: a.tech_id
        }
      )

    withdrawn_query =
      from(
        a in Assignment,
        where:
          a.tech_id == ^tech_id and a.status == "withdrawn" and
            (a.updated_at >= ^start_current_month and a.updated_at <= ^end_current_month),
        select: %{
          id: a.id,
          tech_id: a.tech_id
        }
      )

    from(
      t in Tech,
      left_join: ac in subquery(completed_query),
      on: ac.tech_id == t.id,
      left_join: cb in subquery(callback_query),
      on: cb.tech_id == t.id,
      left_join: aw in subquery(withdrawn_query),
      on: aw.tech_id == t.id,
      where: t.id == ^tech_id,
      select: %{
        id: t.id,
        name: t.name,
        rating: avg(ac.rating),
        callback: jsonize(cb, [:id]),
        complete: jsonize(ac, [:id]),
        withdrawn: jsonize(aw, [:id])
      },
      group_by: t.id
    )
    |> Repo.one(prefix: client_schema)
    |> case do
      nil -> nil
      stats -> Map.put(stats, :date, start_current_month)
    end
  end

  def set_all_categories(%AppCount.Core.ClientSchema{name: client_schema, attrs: tech_id}) do
    category_ids =
      from(
        c in Category,
        select: c.id
      )
      |> Repo.all(prefix: client_schema)

    tech = Repo.get(Tech, tech_id, prefix: client_schema)

    skill_changes(Multi.new(), tech, category_ids)
    |> Repo.transaction(prefix: client_schema)
  end

  defp send_to_tech(%AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: %{id: id, name: name, pass_code: code, email: email}
       }) do
    property_id =
      from(
        j in Job,
        where: j.tech_id == ^id,
        select: j.property_id,
        limit: 1
      )
      |> Repo.one(prefix: client_schema)

    property = AppCount.Properties.get_property(ClientSchema.new(client_schema, property_id))

    AppCountCom.Techs.tech_pass_code(name, code, email, property)
  end

  defp set_tech_jobs({:ok, tech}, %AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: %{"property_ids" => property_ids, "category_ids" => skill_ids}
       }) do
    Multi.new()
    |> job_changes(tech, property_ids)
    |> skill_changes(tech, skill_ids)
    |> Repo.transaction(prefix: client_schema)
  end

  defp set_tech_jobs({:ok, tech}, %AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: %{"category_ids" => skill_ids}
       }) do
    case length(skill_ids) do
      0 ->
        set_all_categories(ClientSchema.new(client_schema, tech.id))

      _ ->
        skill_changes(Multi.new(), tech, skill_ids)
        |> Repo.transaction(prefix: client_schema)
    end
  end

  defp set_tech_jobs({:ok, tech}, %AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: %{"property_ids" => property_ids}
       }) do
    job_changes(Multi.new(), tech, property_ids)
    |> Repo.transaction(prefix: client_schema)
  end

  defp set_tech_jobs({:ok, _}, _), do: nil

  defp set_tech_jobs({:error, e}, _p), do: Logger.error(inspect(e))

  defp job_changes(multi, tech, "clear") do
    to_delete = from(j in Job, where: j.tech_id == ^tech.id)
    Multi.delete_all(multi, :removed_jobs, to_delete)
  end

  defp job_changes(multi, tech, property_ids) do
    to_delete =
      from(j in Job, where: j.tech_id == ^tech.id and j.property_id not in ^property_ids)

    Enum.reduce(
      property_ids,
      multi,
      fn property_id, multi ->
        cs = Job.changeset(%Job{}, %{tech_id: tech.id, property_id: property_id})
        Multi.insert(multi, "job_#{property_id}", cs, on_conflict: :nothing)
      end
    )
    |> Multi.delete_all(:removed_jobs, to_delete)
  end

  defp skill_changes(multi, tech, category_ids) do
    to_delete =
      from(s in Skill, where: s.tech_id == ^tech.id and s.category_id not in ^category_ids)

    Enum.reduce(
      category_ids,
      multi,
      fn category_id, multi ->
        cs = Skill.changeset(%Skill{}, %{tech_id: tech.id, category_id: category_id})
        Multi.insert(multi, "skill_#{category_id}", cs, on_conflict: :nothing)
      end
    )
    |> Multi.delete_all(:removed_skills, to_delete)
  end
end
