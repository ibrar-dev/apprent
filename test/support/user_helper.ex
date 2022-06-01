defmodule AppCount.UserHelper do
  @moduledoc """
  Public User  Helper
  Provide uti
  """
  alias AppCount.Admins.AdminRepo

  @top 1_000_000

  def new_admin(custom \\ %{}) do
    unique_1 = Enum.random(1..@top)
    unique_2 = Enum.random(100..@top)

    attrs =
      %{
        name: "admin-#{unique_1}#{unique_2}",
        email: "admin-#{unique_1}#{unique_2}@example.com",
        username: "username-admin-#{unique_1}#{unique_2}",
        password_hash: "hash",
        roles: ["Admin"]
      }
      |> Map.merge(Map.new(custom))

    # This is perfered approach. Use Production code to create
    {:ok, %{id: admin_id}} = AdminRepo.insert(attrs)

    admin = AdminRepo.get(admin_id)
    client = AppCount.Public.get_client_by_schema("dasmen")

    user_params =
      Map.merge(Map.from_struct(admin), %{
        type: "Admin",
        tenant_account_id: admin.id,
        password: "test_password",
        client_id: client.id,
        username: admin.email
      })

    user =
      case AppCount.Public.Accounts.create_user(user_params) do
        {:ok, user} ->
          AppCount.Public.Accounts.get_user!(user.id)
      end

    Map.put(admin, :user, user)
  end

  def new_account(account, custom \\ %{}) do
    client = AppCount.Public.get_client_by_schema("dasmen")

    attrs =
      %{
        username: account.username,
        password: "test_password",
        client_id: client.id,
        type: "Tenant",
        tenant_account_id: account.id
      }
      |> Map.merge(Map.new(custom))

    user =
      case AppCount.Public.Accounts.create_user(attrs) do
        {:ok, user} ->
          AppCount.Public.Accounts.get_user!(user.id)

        ttt ->
          ttt
      end

    {:ok, account} = AppCount.Accounts.AccountRepo.update(account, %{public_user_id: user.id})
    Map.put(account, :user, user)
  end

  def new_app_rent_user(custom \\ %{}) do
    attrs =
      %{
        username: "apprent",
        password: "test_password"
      }
      |> Map.merge(Map.new(custom))

    AppCount.Public.Accounts.create_app_rent_user(attrs)
  end
end
