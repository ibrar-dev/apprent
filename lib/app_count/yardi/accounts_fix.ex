defmodule AppCount.Yardi.AccountsFix do
  import Ecto.Query
  alias AppCount.Tenants.Tenant
  alias AppCount.Repo
  require Logger

  def create_accounts() do
    from(
      t in Tenant,
      left_join: a in assoc(t, :account),
      where: is_nil(a) and not is_nil(t.email),
      select: t.id
    )
    |> Repo.all()
    |> Enum.each(&AppCount.Accounts.create_tenant_account(&1))
  end
end
