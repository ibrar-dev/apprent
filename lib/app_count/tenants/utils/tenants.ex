defmodule AppCount.Tenants.Utils.Tenants do
  alias AppCount.Repo
  alias AppCount.Properties.Property
  alias AppCount.Tenants.Tenant
  alias AppCount.Tenants.TenancyRepo
  alias AppCount.Leases.Lease
  import Ecto.Query
  import AppCount.EctoExtensions

  def list_tenants(admin) do
    admin
    |> list_tenants_query
    |> Repo.all()
  end

  def list_tenants(admin, property_id) do
    admin
    |> list_tenants_query
    |> where([_, _, _, unit], unit.property_id == ^property_id)
    |> Repo.all(prefix: admin.client_schema)
  end

  def list_tenants_min(admin) do
    today_date = AppCount.current_time()

    from(
      t in Tenant,
      join: l in assoc(t, :leases),
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      select: %{
        id: t.id,
        name: fragment("? || ' ' || ?", t.first_name, t.last_name),
        email: t.email,
        leases:
          jsonize(
            l,
            [
              u.id,
              u.number,
              {:property, p.name},
              {:current_tenant, is_nil(l.actual_move_out) or l.actual_move_out > ^today_date}
            ]
          )
      },
      where: p.id in ^admin.property_ids,
      group_by: t.id
    )
    |> Repo.all(prefix: admin.client_schema)
  end

  # Tenants sometimes see bounced emails -- this lets us clear those out for a
  # given tenant
  def clear_bounces(tenant_id) do
    tenant = Repo.get(Tenant, tenant_id)

    case tenant do
      %Tenant{email: email} ->
        AppCount.Messaging.clear_bounces(email)

      _ ->
        nil
    end
  end

  def update_tenant(id, params) do
    Repo.get(Tenant, id)
    |> Tenant.changeset(params)
    |> Repo.update()
  end

  @spec property_for(integer) :: %Property{} | nil
  def property_for(tenant_id) do
    tenancy = TenancyRepo.active_tenancy_for_tenant(tenant_id)

    if tenancy do
      from(
        u in AppCount.Properties.Unit,
        join: p in assoc(u, :property),
        left_join: i in assoc(p, :icon_url),
        left_join: lo in assoc(p, :logo_url),
        where: u.id == ^tenancy.unit_id,
        select: p,
        select_merge: %{
          icon: i.url,
          logo: lo.url
        }
      )
      |> Repo.one()
    end
  end

  def send_individual_email(%{
        "body" => body,
        "subject" => subject,
        "tenant_id" => tenant_id,
        "attachments" => a
      }) do
    property = property_for(tenant_id)

    email =
      from(
        t in Tenant,
        where: t.id == ^tenant_id,
        select: t.email
      )
      |> Repo.one()

    AppCountCom.Messaging.send_individual_email(subject, body, a, email, property)
  end

  @spec get_tenants_charges(integer | String.t()) :: %Decimal{}
  def get_tenants_charges(tenant_id) do
    # TODO use occupancy and have TenantRepo load current occupancy.
    from(
      l in Lease,
      join: c in assoc(l, :charges),
      where: l.id == ^AppCount.Tenants.TenantRepo.current_lease_for(tenant_id).id,
      select: sum(c.amount)
    )
    |> Repo.one()
  end

  defp list_tenants_query(admin) do
    today_date = AppCount.current_time()
    haprent_code = AppCount.Accounting.SpecialAccounts.get_charge_code(:hap_rent).id

    from(
      tenant in Tenant,
      join: lease in assoc(tenant, :leases),
      left_join: eviction in assoc(lease, :eviction),
      join: unit in assoc(lease, :unit),
      join: property in assoc(unit, :property),
      left_join: account in assoc(tenant, :account),
      left_join: logins in assoc(account, :logins),
      left_join: autopay in assoc(account, :autopay),
      left_join: bounce in AppCount.Messaging.Bounce,
      on: bounce.target == tenant.email,
      left_join: hc in AppCount.Properties.Charge,
      on:
        lease.id == hc.lease_id and hc.charge_code_id == ^haprent_code and
          (is_nil(hc.to_date) or hc.to_date >= ^AppCount.current_date()) and
          (is_nil(hc.from_date) or hc.from_date <= ^AppCount.current_date()),
      select: map(tenant, [:id]),
      select_merge: %{
        name: fragment("? || ' ' || ?", tenant.first_name, tenant.last_name),
        account: account.id,
        autopay: autopay.active,
        email: tenant.email,
        bounce_id: bounce.id,
        logins:
          jsonize(
            logins,
            [
              :id,
              :inserted_at,
              :type
            ],
            logins.inserted_at,
            "DESC"
          ),
        leases:
          jsonize(
            lease,
            [
              :id,
              :start_date,
              :end_date,
              unit.number,
              {:property, property.name},
              {:current_tenant,
               is_nil(lease.actual_move_out) or lease.actual_move_out > ^today_date},
              :actual_move_out,
              :actual_move_in,
              :no_renewal,
              {:evicted, not is_nil(eviction.id)},
              :renewal_id,
              {:current_haprent, not is_nil(hc)}
            ],
            lease.start_date,
            "DESC"
          )
      },
      where: property.id in ^admin.property_ids,
      group_by: [tenant.id, account.id, bounce.id, autopay.active]
    )
  end
end
