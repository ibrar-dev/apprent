defmodule AppCount.Accounts.Autopays.SendReminder do
  import Ecto.Query
  alias AppCount.Accounts.Autopay
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema

  # Given all active Autopays, send the reminder email to each
  def perform(schema) do
    autopays = get_list_of_autopays(schema)

    Enum.each(autopays, fn autopay -> send_email(autopay) end)
  end

  def get_list_of_autopays(schema) do
    from(
      a in Autopay,
      join: ac in assoc(a, :account),
      join: ps in assoc(a, :payment_source),
      where: a.active and ps.active,
      select: %{
        tenant_id: ac.tenant_id,
        property_id: ac.property_id
      }
    )
    |> Repo.all(prefix: schema)
  end

  def send_email(%{tenant_id: tenant_id, property_id: property_id}) do
    tenant = AppCount.Tenants.TenantRepo.get_aggregate(tenant_id)
    # TODO:SCHEMA remove dasmen
    property = AppCount.Properties.get_property(ClientSchema.new("dasmen", property_id))

    AppCountCom.Tenants.autopay_reminder(%{tenant: tenant, property: property})
  end
end
