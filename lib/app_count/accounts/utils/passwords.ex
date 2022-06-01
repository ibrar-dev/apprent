defmodule AppCount.Accounts.Utils.Passwords do
  alias AppCount.Repo
  alias AppCount.Accounts
  alias AppCount.Public.UserRepo
  alias AppCount.Tenants.TenancyRepo
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def reset_password_request(username) do
    UserRepo.get_by([username: username, type: "Tenant"], prefix: "public")
    |> Repo.preload(:client)
    |> case do
      nil ->
        {:error, :no_username}

      %AppCount.Public.User{id: user_id, tenant_account_id: account_id, client: client} ->
        account =
          AppCount.Accounts.AccountRepo.get(account_id, [:tenant], prefix: client.client_schema)

        property_id =
          TenancyRepo.current_tenancies_query()
          |> where([t], t.tenant_id == ^account.tenant_id)
          |> join(:inner, [t], u in assoc(t, :unit))
          |> select([t, u], u.property_id)
          |> Repo.one(prefix: client.client_schema)

        cond do
          property_id && account.tenant.email ->
            property =
              AppCount.Properties.get_property(
                ClientSchema.new(client.client_schema, property_id)
              )

            token(user_id)
            |> AppCountCom.Accounts.reset_password(account.tenant.email, username, property)

            {:ok, account.tenant.email}

          is_nil(account.tenant.email) ->
            {:error, :no_email}

          is_nil(property_id) ->
            {:error, :no_property_assoc}
        end
    end
  end

  @spec reset_password(String.t(), String.t(), String.t()) ::
          {:ok, %Accounts.Account{}} | {:error, String.t()}
  def reset_password(token, password, confirmation) when password == confirmation do
    # FIX_DEPS
    case AppCountWeb.Token.verify(token) do
      {:ok, public_user_id} ->
        UserRepo.get(public_user_id, [:client], prefix: "public")
        |> AppCount.Public.User.changeset(%{password: password})
        |> Repo.update(prefix: "public")

      {:error, :invalid} ->
        {:error, "Invalid token"}

      {:error, :expired} ->
        {:error, "Token expired"}
    end
  end

  def reset_password(_, _, _), do: {:error, "Password does not match confirmation"}

  # Better: move up stack

  def token(account_id) do
    # FIX_DEPS
    AppCountWeb.Token.token(account_id)
  end
end
