defmodule AppCount.Admins do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Admins.Admin
  alias AppCount.Admins.Region
  alias AppCount.Admins.Permission
  alias AppCount.Admins.Message
  alias AppCount.Admins.Utils.Devices
  alias AppCount.Admins.Utils.Admins
  alias AppCount.Admins.Utils.Entities
  alias AppCount.Admins.Utils.Profiles
  alias AppCount.Admins.Utils.Alerts
  alias AppCount.Admins.Utils.Actions
  alias AppCount.Admins.Utils.Passwords
  alias AppCount.Admins.Utils.OrgCharts
  alias AppCount.Messaging.BounceRepo
  alias AppCount.Properties.Scoping
  alias AppCount.Properties.Property
  alias AppCount.Admins.EmailSubscriptionsRepo
  alias AppCount.Core.ClientSchema

  def list_admins(params), do: Admins.list_admins(params)
  def list_agents(admin), do: Admins.list_agents(admin)
  def property_ids_for(admin), do: Admins.property_ids_for(admin)
  def property_ids_for(admin, type), do: Admins.property_ids_for(admin, type)

  # UNUSED ?
  def filtered_property_ids_for(admin, property_ids),
    do: Admins.filtered_property_ids_for(admin, property_ids)

  def create_admin(params), do: Admins.create_admin(params)
  def update_admin(admin_id, params), do: Admins.update_admin(admin_id, params)
  def delete_admin(admin, id), do: Admins.delete_admin(admin, id)
  def get_admin!(id), do: Admins.get_admin!(id)
  def list_tech_admins(admin), do: Admins.list_tech_admins(admin)

  def has_permission?(admin, property_id),
    do: Admins.has_permission?(admin, property_id)

  def reset_password_request(email), do: Passwords.reset_password_request(email)

  def reset_password(token, password, confirmation),
    do: Passwords.reset_password(token, password, confirmation)

  def list_entities(client_schema), do: Entities.list_entities(client_schema)
  def get_entity!(id), do: Entities.get_entity!(id)
  def create_entity(params), do: Entities.create_entity(params)
  def update_entity(entity_id, params), do: Entities.update_entity(entity_id, params)
  def delete_entity(entity_id), do: Entities.delete_entity(entity_id)

  def list_devices(schema), do: Devices.list_devices(schema)
  def get_device(id, nonce), do: Devices.get_device(id, nonce)
  def update_device(id, params), do: Devices.update_device(id, params)
  def delete_device(id), do: Devices.delete_device(id)

  def create_profile(params), do: Profiles.create_profile(params)
  def update_profile(id, params), do: Profiles.update_profile(id, params)
  def delete_profile(admin, id), do: Profiles.delete_profile(admin, id)

  def get_total_unread(admin_id), do: Alerts.get_total_unread(admin_id)
  def create_alert(params), do: Alerts.create_alert(params)
  def create_alert(params, :nonsave), do: Alerts.create_alert(params, :nonsave)
  def update_alert(id, params), do: Alerts.update_alert(id, params)
  def read_alert(id), do: Alerts.read_alert(id)
  def unread_alert(id), do: Alerts.unread_alert(id)
  def get_alerts(admin_id), do: Alerts.get_alerts(admin_id)
  def delete_alert(alert_id), do: Alerts.delete_alert(alert_id)

  ## Email Subscriptions
  def get_subscriptions(admin_id),
    do: EmailSubscriptionsRepo.get_subscriptions(admin_id)

  def subscribe(admin_id, trigger),
    do: EmailSubscriptionsRepo.subscribe(admin_id, trigger)

  def unsubscribe(admin_id, trigger),
    do: EmailSubscriptionsRepo.unsubscribe(admin_id, trigger)

  ## ORG CHART
  def create_root(params), do: OrgCharts.create_root(params)
  def update_org(params), do: OrgCharts.update(params)
  def delete_org(id), do: OrgCharts.delete(id)
  def list_org(admin), do: OrgCharts.index(admin.id)
  def get_parent(id), do: OrgCharts.get_parent(id)
  def descendants(admin), do: OrgCharts.descendants(admin)
  def get_everyone(schema), do: OrgCharts.get_everyone(schema)

  def list_actions(params), do: Actions.list_actions(params)
  def get_actions(params), do: Actions.get_actions(params)

  def get_admin_roles(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: id
        },
        _params
      ) do
    from(
      a in Admin,
      where: ^id == a.id,
      select: %{
        id: a.id,
        name: a.name,
        email: a.email,
        roles: a.roles
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def attach_admin(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: %Region{} = entity
        },
        %Admin{} = admin
      ) do
    attach_admin(
      %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: entity.id
      },
      admin.id
    )
  end

  def attach_admin(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: entity_id
        },
        admin_id
      ) do
    %Permission{}
    |> Permission.changeset(%{admin_id: admin_id, region_id: entity_id})
    |> Repo.insert(prefix: client_schema)
  end

  def detach_admin(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: region_id
        },
        admin_id
      ) do
    from(p in Permission, where: p.region_id == ^region_id and p.admin_id == ^admin_id)
    |> Repo.one(prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  def attach_property_to_entity(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: region_id
        },
        property_id
      ) do
    %Scoping{}
    |> Scoping.changeset(%{region_id: region_id, property_id: property_id})
    |> Repo.insert(prefix: client_schema)
  end

  def detach_property_from_entity(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: region_id
        },
        property_id
      ) do
    from(s in Scoping, where: s.region_id == ^region_id and s.property_id == ^property_id)
    |> Repo.one(prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  def entity_descriptor(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %Admin{} = admin
      }) do
    from(
      p in Permission,
      where: p.admin_id == ^admin.id,
      left_join: e in assoc(p, :region),
      left_join: s in assoc(e, :scopings),
      select: %{
        resources: e.resources,
        property_id: s.property_id
      }
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.reduce(
      %{},
      fn entity, acc ->
        resources =
          (Map.get(acc, entity.property_id) || [])
          |> Enum.concat(entity.resources)
          |> Enum.uniq()

        Map.put(acc, entity.property_id, resources)
      end
    )
  end

  # unneeded
  @spec has_role?(String.t(), MapSet.t()) :: boolean()
  def has_role?(
        _role,
        %MapSet{
          map: %{
            "Super Admin" => []
          }
        }
      ) do
    true
  end

  # unused
  def has_role?(role, roles) when is_list(role) do
    sect =
      MapSet.new(role)
      |> MapSet.intersection(roles)
      |> MapSet.size()

    sect > 0
  end

  # deprecated.  use: AppCount.Admins.Admin.has_role?/2
  def has_role?(role, roles) do
    MapSet.member?(roles, role)
  end

  def admins_for(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: property_id
        },
        role \\ ["Admin"]
      ) do
    entity_ids =
      from(
        s in Scoping,
        where: s.property_id == ^property_id,
        select: s.region_id
      )
      |> Repo.all(prefix: client_schema)

    from(
      a in Admin,
      join: e in assoc(a, :regions),
      where: e.id in ^entity_ids and fragment("? && ?", ^role, a.roles),
      group_by: a.id
    )
    |> Repo.all(prefix: client_schema)
  end

  def properties_for(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %{
          roles: %MapSet{
            map: %{
              "Super Admin" => _
            }
          }
        }
      }) do
    Repo.all(Property, prefix: client_schema)
  end

  def properties_for(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      }) do
    from(
      e in Region,
      join: p in assoc(e, :permissions),
      join: s in assoc(e, :scopings),
      join: prop in assoc(s, :property),
      where: p.admin_id == ^admin.id,
      select: prop
    )
    |> Repo.all(prefix: client_schema)
  end

  @spec admin_from_token(String.t()) :: %Admin{} | {:error, :bad_auth}
  def admin_from_token(token) do
    case AppCount.Admins.Auth.Tokens.verify(token) do
      {:ok, admin, _} -> admin
      _ -> {:error, :bad_auth}
    end
  end

  def create_message(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: category
        },
        content,
        admin_id
      ) do
    %Message{}
    |> Message.changeset(%{category: category, content: content, admin_id: admin_id})
    |> Repo.insert!(prefix: client_schema)
    |> notify_admin_message
  end

  def list_messages(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin
      }) do
    from(
      m in Message,
      where: m.admin_id == ^admin.id,
      order_by: [
        desc: m.created_at
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def notify_admin_message(%Message{admin_id: _admin_id}) do
  end

  def bounce_admin_email(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin_id
        },
        bounce_status
      ) do
    admin =
      Admins.get_admin!(
        ClientSchema.new(
          client_schema,
          admin_id
        )
      )

    email = admin.email

    do_bounce_admin_email(
      ClientSchema.new(
        client_schema,
        email
      ),
      bounce_status
    )
  end

  def do_bounce_admin_email(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin_email
        },
        true
      ) do
    BounceRepo.insert(%{target: admin_email}, prefix: client_schema)
  end

  def do_bounce_admin_email(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin_email
        },
        false
      ) do
    import Ecto.Query
    alias AppCount.Messaging.Bounce

    from(
      bounce in Bounce,
      where: bounce.target == ^admin_email
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.map(fn bounce -> bounce.id end)
    |> Enum.each(&BounceRepo.delete(ClientSchema.new(client_schema, &1)))
  end
end
