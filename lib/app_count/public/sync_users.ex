defmodule AppCount.Public.SyncUsers do
  @moduledoc """
    Function to construct the public.users table from all of the tenant accounts and admins in the tenant schemas.
    This will need to be done when we initially move to logging in based the public users table as well as whenever the
    public users table falls out of sync with the tenant tables, such as after we restore a client's data from backup.

    sync_all_users/1 takes a list of schemas for which we want to rebuild the users list. The order of the schemas
    will determine which ones get priority when it comes to username conflicts, so if we have "dasmen" and "ezrent"
    clients passing in ["ezrent", "dasmen"] will potentially change some usernames in "dasmen" whereas passing
    in ["dasmen", "ezrent"] would cause ezrent usernames to change if they conflicted with dasmen ones.
  """
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Public.Client
  alias AppCount.Public.User
  alias AppCount.Public.Accounts

  def sync_all_users(schema_list) when is_list(schema_list) do
    # PLEASE NOTE this call to Repo.all does NOT need a prefix nor should it get one
    user_sync_query(schema_list)
    |> Repo.all()
    |> Enum.map(&do_sync/1)
    |> Enum.each(&add_ref/1)
  end

  def user_sync_query(schema_list) do
    [first_client | rest] =
      Repo.all(Client, prefix: "public")
      |> Enum.filter(&Enum.member?(schema_list, &1.client_schema))

    initial_query =
      admins_query(first_client)
      |> union_all(^tenants_query(first_client))
      |> union_all(^techs_query(first_client))

    Enum.reduce(
      rest,
      initial_query,
      fn client, query ->
        query
        |> union_all(^admins_query(client))
        |> union_all(^tenants_query(client))
        |> union_all(^techs_query(client))
      end
    )
  end

  def admins_query(client) do
    from(
      admin in AppCount.Admins.Admin,
      select: %{
        username: admin.email,
        type: "Admin",
        tenant_account_id: admin.id,
        password_hash: admin.password_hash,
        client_id: type(^client.id, :integer),
        schema: ^client.client_schema
      }
    )
    |> Map.put(:prefix, client.client_schema)
  end

  def tenants_query(client) do
    from(
      account in AppCount.Accounts.Account,
      select: %{
        username: account.username,
        type: "Tenant",
        tenant_account_id: account.id,
        password_hash: account.encrypted_password,
        client_id: type(^client.id, :integer),
        schema: ^client.client_schema
      }
    )
    |> Map.put(:prefix, client.client_schema)
  end

  def techs_query(client) do
    from(
      tech in AppCount.Maintenance.Tech,
      select: %{
        username: type(tech.identifier, :string),
        type: "Tech",
        tenant_account_id: tech.id,
        password_hash: "N/A",
        client_id: type(^client.id, :integer),
        schema: ^client.client_schema
      }
    )
    |> Map.put(:prefix, client.client_schema)
  end

  defp do_sync(entry) do
    result =
      case get_existing(entry) do
        nil ->
          %{entry | username: Accounts.unique_username(entry.username, entry.type)}
          |> Accounts.create_user()

        existing ->
          Accounts.update_user(existing, entry)
      end

    Tuple.append(result, entry.schema)
  end

  defp get_existing(entry) do
    params =
      entry
      |> Map.take([:tenant_account_id, :client_id, :type])
      |> Map.to_list()

    Repo.get_by(User, params, prefix: "public")
  end

  defp add_ref({:ok, %User{type: "Tenant"} = user, schema}),
    do: do_update(AppCount.Accounts.Account, user, schema)

  defp add_ref({:ok, %User{type: "Admin"} = user, schema}),
    do: do_update(AppCount.Admins.Admin, user, schema)

  defp add_ref({:ok, %User{type: "Tech"} = user, schema}),
    do: do_update(AppCount.Maintenance.Tech, user, schema)

  defp add_ref(e), do: e

  defp do_update(module, %User{tenant_account_id: id, id: public_id}, schema) do
    Repo.get(module, id)
    |> module.changeset(%{public_user_id: public_id})
    |> Repo.update(prefix: schema)
  end
end
