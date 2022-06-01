defmodule AppCount.Accounts.Utils.Tokens do
  # alias AppCount.Repo
  # import Ecto.Query

  def get_token(user_uuid) do
    # FIX_DEPS
    AppCountWeb.Token.token(user_uuid)
  end

  def verify_token(token) do
    # FIX_DEPS
    # AppCountWeb.Token.verify(token)
    # with {:ok, user} when is_map(user) <-
    #        AppCountWeb.Token.verify(token),
    #      %{} = account <- user_info(user.account_id, user.client_schema) do
    #   {:ok, account,
    #    get_token(%{
    #      tenant_account_id: user.tenant_account_id,
    #      account_id: user.account_id,
    #      user_id: user.user_id,
    #      schema: user.client_schema
    #    })}
    # else
    #   _ -> {:error, :bad_token}
    # end

    case AppCountWeb.Token.verify(token) do
      {:ok, user} -> {:ok, user, AppCountWeb.Token.token(user)}
      _ -> {:error, :bad_token}
    end
  end

  # defp user_info(account_id, schema) do
  #   # This appears to be a "User" in the system
  #   from(
  #     t in AppCount.Tenants.Tenant,
  #     join: a in assoc(t, :account),
  #     join: p in assoc(a, :property),
  #     left_join: l in assoc(p, :logo_url),
  #     left_join: i in assoc(p, :icon_url),
  #     where: a.id == ^account_id,
  #     select:
  #       map(a, [
  #         :password_changed,
  #         :autopay,
  #         :receives_mailings,
  #         :uuid,
  #         :profile_pic,
  #         :preferred_language
  #       ]),
  #     select_merge:
  #       map(t, [:id, :email, :first_name, :last_name, :phone, :alarm_code, :payment_status]),
  #     select_merge: %{
  #       property: %{
  #         id: p.id,
  #         name: p.name,
  #         icon: i.url,
  #         logo: l.url
  #       }
  #     },
  #     select_merge: %{
  #       account_id: a.id,
  #       name: fragment("? || ' ' || ?", t.first_name, t.last_name)
  #     }
  #   )
  #   |> Repo.one(prefix: schema)
  # end
end
