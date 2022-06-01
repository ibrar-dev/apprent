defmodule AppCount.Admins.Utils.Admins do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Admins.Admin
  alias AppCount.Admins.Region
  alias AppCount.Properties.Property
  alias AppCount.Admins.AdminRepo
  alias AppCount.Public.ClientRepo
  alias AppCount.Core.ClientSchema

  def list_admins(%AppCount.Core.ClientSchema{name: client_schema, attrs: nil}) do
    Repo.all(
      from(
        a in Admin,
        left_join: p in assoc(a, :permissions),
        left_join: b in assoc(a, :profile),
        left_join: image in assoc(b, :image_url),
        # left_join: ll in subquery(last_login),
        # on: ll.admin_id == a.id,
        select: %{
          id: a.id,
          name: a.name,
          username: a.username,
          email: a.email,
          roles: a.roles,
          entity_ids: fragment("array_remove(array_agg(?), NULL)", p.region_id),
          reset_pw: a.reset_pw,
          #          last_login: ll.inserted_at,
          profile: %{
            id: b.id,
            image: image.url,
            bio: b.bio,
            active: b.active,
            title: b.title
          }
        },
        group_by: [a.id, b.id, image.url],
        order_by: [
          asc: :name
        ]
      ),
      prefix: client_schema
    )
  end

  def list_admins(%AppCount.Core.ClientSchema{name: client_schema, attrs: _admin} = wrapped_admin) do
    property_ids = property_ids_for(wrapped_admin)

    from(
      a in Admin,
      left_join: e in assoc(a, :regions),
      left_join: p in assoc(e, :properties),
      select: %{
        id: a.id,
        name: a.name,
        reset_pw: a.reset_pw,
        properties: fragment("array_agg(DISTINCT ?)", p.id)
      },
      where: p.id in ^property_ids,
      group_by: a.id
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_agents(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}) do
    property_ids = property_ids_for(admin)

    from(
      a in Admin,
      left_join: e in assoc(a, :regions),
      left_join: p in assoc(e, :properties),
      select: %{
        id: a.id,
        name: a.name,
        username: a.username,
        email: a.email
      },
      group_by: a.id,
      where: fragment("'Agent' = ANY(?)", a.roles) and p.id in ^property_ids,
      order_by: [
        asc: :name
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_tech_admins(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}) do
    property_ids = admin.property_ids

    from(
      a in Admin,
      left_join: e in assoc(a, :regions),
      left_join: p in assoc(e, :properties),
      where: fragment("'Tech' = ANY(?)", a.roles) and p.id in ^property_ids,
      group_by: a.id,
      select: %{
        id: a.id,
        name: a.name
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_admin!(%AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    from(
      admin in Admin,
      left_join: p in assoc(admin, :permissions),
      left_join: b in assoc(admin, :profile),
      left_join: image in assoc(b, :image_url),
      select: %{
        id: admin.id,
        name: admin.name,
        username: admin.username,
        email: admin.email,
        roles: admin.roles,
        entity_ids: fragment("array_remove(array_agg(?), NULL)", p.region_id),
        reset_pw: admin.reset_pw,
        active: admin.active,
        profile: %{
          id: b.id,
          image: image.url,
          bio: b.bio,
          active: b.active,
          title: b.title
        }
      },
      where: admin.id == ^id,
      group_by: [admin.id, b.id, image.url],
      order_by: [
        asc: :name
      ]
    )
    |> Repo.one(prefix: client_schema)
  end

  def create_admin(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    case client_id_from_schema(client_schema) do
      {:ok, client_id} ->
        Ecto.Multi.new()
        |> Ecto.Multi.run(:initial_admin, fn _, _ ->
          AdminRepo.insert(params, prefix: client_schema)
        end)
        |> Ecto.Multi.run(:public_admin, fn _repo, cs ->
          params
          |> Morphix.atomorphiform!()
          |> Map.merge(%{
            type: "Admin",
            tenant_account_id: cs.initial_admin.id,
            client_id: client_id
          })
          |> AppCount.Public.Accounts.create_user()
        end)
        |> Ecto.Multi.run(:admin, fn _repo, cs ->
          AdminRepo.update(cs.initial_admin, %{public_user_id: cs.public_admin.id},
            prefix: client_schema
          )
        end)
        |> Repo.transaction()
        |> case do
          {:ok, %{admin: admin}} -> {:ok, admin}
          e -> e
        end

      e ->
        e
    end
  end

  def update_admin(admin_id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params})
      when is_binary(client_schema) do
    Repo.get(Admin, admin_id, prefix: client_schema)
    |> Admin.changeset(params)
    |> Repo.update(prefix: client_schema)
    |> case do
      {:ok, admin} ->
        case AppCount.Public.Accounts.get_admin_by_tenant_account_id(admin.id, client_schema) do
          nil ->
            {:ok, admin}

          user ->
            case AppCount.Public.Accounts.update_user(user, params) do
              {:ok, _user} ->
                {:ok, admin}

              {:error, changeset} ->
                # delete admin already added
                {:error, changeset}
            end
        end

      error ->
        error
    end
  end

  def delete_admin(_admin, %AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    Repo.get(Admin, id, prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  # UNUSED ?
  def filtered_property_ids_for(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: %{
            roles: %MapSet{
              map: %{
                "Super Admin" => _
              }
            }
          }
        },
        _
      ) do
    from(
      p in Property,
      select: p.id
    )
    |> Repo.all(prefix: client_schema)
  end

  # UNUSED ?
  def filtered_property_ids_for(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: %Admin{} = admin
        },
        property_ids
      ) do
    from(
      e in Region,
      join: p in assoc(e, :permissions),
      join: s in assoc(e, :scopings),
      join: property in assoc(s, :property),
      join: ps in assoc(property, :setting),
      where: p.admin_id == ^admin.id and ps.active and property.id in ^property_ids,
      select: s.property_id
    )
    |> Repo.all(prefix: client_schema)
  end

  def property_ids_for(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: %{
            roles: %MapSet{
              map: %{
                "Super Admin" => _
              }
            }
          }
        },
        :all
      ) do
    from(
      p in Property,
      select: p.id
    )
    |> Repo.all(prefix: client_schema)
  end

  def property_ids_for(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, _) do
    # Middle man
    # AppCount.Admins.AccessServer.property_ids_for(ClientSchema.new("dasmen", admin))
    AppCount.Admins.AccessServer.Loader.property_ids_for(ClientSchema.new(client_schema, admin))
  end

  def property_ids_for(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin_id})
      when is_integer(admin_id) do
    admin = Repo.get(Admin, admin_id, prefix: client_schema)

    ClientSchema.new(client_schema, admin)
    |> property_ids_for()
  end

  def property_ids_for(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}) do
    # Middle man
    # AppCount.Admins.AccessServer.property_ids_for(ClientSchema.new("dasmen", admin))
    AppCount.Admins.AccessServer.Loader.property_ids_for(ClientSchema.new(client_schema, admin))
  end

  def property_ids_for(admin) do
    admin
    |> ClientSchema.new()
    |> property_ids_for()
  end

  def has_permission?(
        %{
          roles: %MapSet{
            map: %{
              "Super Admin" => _
            }
          }
        },
        _,
        _
      ),
      do: true

  def has_permission?(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, property_id) do
    count =
      from(
        e in Region,
        join: p in assoc(e, :permissions),
        join: s in assoc(e, :scopings),
        where: p.admin_id == ^admin.id,
        where: s.property_id == ^property_id,
        select: count(s.id)
      )
      |> Repo.one(prefix: client_schema)

    count > 0
  end

  # TODO:SCHEMA has_permission/2 after
  def has_permission?(
        %{
          roles: %MapSet{
            map: %{
              "Super Admin" => _
            }
          }
        },
        _
      ),
      do: true

  def has_permission?(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, property_id) do
    count =
      from(
        e in Region,
        join: p in assoc(e, :permissions),
        join: s in assoc(e, :scopings),
        where: p.admin_id == ^admin.id,
        where: s.property_id == ^property_id,
        select: count(s.id)
      )
      |> Repo.one(prefix: client_schema)

    count > 0
  end

  defp client_id_from_schema(nil), do: {:error, "invalid client schema"}

  defp client_id_from_schema(schema) do
    ClientRepo.from_schema(schema)
    |> case do
      nil -> {:error, "invalid client schema"}
      client -> {:ok, client.id}
    end
  end
end
