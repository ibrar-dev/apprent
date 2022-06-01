defmodule AppCount.Accounts.AccountRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Accounts.Account

  alias AppCount.Tenants.Tenant

  def get_by_tenant(%Tenant{id: tenant_id}) do
    get_by_tenant(tenant_id)
  end

  def get_by_tenant(%{tenant_id: tenant_id}) do
    get_by_tenant(tenant_id)
  end

  def get_by_tenant(tenant_id) when is_integer(tenant_id) do
    from(
      a in @schema,
      where: a.tenant_id == ^tenant_id
    )
    |> Repo.one()
  end

  def get_account_extras(%Tenant{} = tech) do
    tech
    |> Repo.preload(account: [:logins, :autopay])
  end

  def get_account_extras(tenant_id) do
    Repo.get_by(@schema, tenant_id: tenant_id)
    |> Repo.preload([:logins, :autopay])
  end
end
