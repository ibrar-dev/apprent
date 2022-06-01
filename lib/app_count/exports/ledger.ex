defmodule AppCount.Exports.Ledger do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Tenants
  alias AppCount.Accounts

  def get_ledger(tenant_id, unit_id, date \\ AppCount.current_date()) do
    unit_info = Accounts.unit_info(tenant_id)
    tenant_data = Tenants.Utils.TenantData.basic_tenant_info(tenant_id, unit_id)

    ledger =
      AppCount.Tenants.ledger_query(tenant_id: tenant_id, unit_id: unit_id)
      |> where([c], c.date <= ^date)
      |> Repo.all()

    %{unit_info: unit_info, ledger: ledger, tenant: tenant_data}
  end
end
