defmodule AppCount.Tenants.TenantRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Tenants.Tenant,
    topic: AppCount.Core.TenantTopic,
    preloads: [
      account: [logins: [], locks: [], payment_sources: [], autopay: [:payment_source]],
      tenancies: [unit: [property: [logo_url: [], icon_url: []]]]
    ]

  alias AppCount.Leases.Lease
  alias AppCount.Properties.Unit
  alias AppCount.Core.DateTimeRange
  alias AppCount.Accounts.Autopay

  # TODO We should also create a second query current_lease_for/2
  # current_lease_for/2 will take a tenant_id and a date
  # and return the current lease as of the passed in date.
  @spec current_lease_for(integer | String.t(), %Date{}) :: %Lease{}
  def current_lease_for(tenant_id, date \\ AppCount.current_date()) do
    tenant_id
    |> current_lease_query(date)
    |> Repo.one()
  end

  @spec current_lease_query(integer | String.t(), %Date{}) :: %Ecto.Query{}
  def current_lease_query(tenant_id, date \\ AppCount.current_date()) do
    from(
      l in Lease,
      join: t in assoc(l, :tenants),
      left_join: r in assoc(l, :renewal),
      where: t.id == ^tenant_id,
      where: l.start_date <= ^date,
      where: is_nil(l.actual_move_out),
      where: is_nil(l.renewal_id) or r.start_date > ^date,
      order_by: [
        desc: l.start_date
      ],
      limit: 1
    )
  end

  def tenants_for_property(property_ids, date \\ AppCount.current_date())

  def tenants_for_property(property_ids, date) when is_list(property_ids) do
    current_tenants_query(date)
    |> where([unit], unit.property_id in ^property_ids)
    |> Repo.all()
  end

  def tenants_for_property(property_id, date) do
    current_tenants_query(date)
    |> where([unit], unit.property_id == ^property_id)
    |> Repo.all()
  end

  # TEST TODO
  def property_for_tenant(tenant_id) do
    AppCount.Tenants.TenancyRepo.current_tenancies_query()
    |> join(:inner, [t], u in assoc(t, :unit))
    |> join(:inner, [t, u], p in assoc(u, :property))
    |> where([t], t.tenant_id == ^tenant_id)
    |> select([_, _, p], p)
    |> Repo.one()
  end

  def tenants_for_unit(%AppCount.Properties.Unit{} = unit, %DateTimeRange{} = datetime_range) do
    unit = Repo.preload(unit, leases: [:tenants])
    date_range = DateTimeRange.date_range(datetime_range)

    unit
    |> AppCount.Properties.Unit.current_lease(date_range.last)
    # was zero or one tenant
    # will be zero, one, many tenants
    |> lease_tenants()
  end

  defp lease_tenants(nil) do
    []
  end

  defp lease_tenants(%Lease{tenants: tenants}) do
    tenants
  end

  def tenant_by_phone_num(num) do
    regex =
      num
      |> String.split("")
      |> Enum.map(&(&1 <> "\\D*"))
      |> Enum.join()

    from(
      t in @schema,
      where: fragment("? ~ ?", t.phone, ^regex),
      preload: ^@preloads
    )
    |> Repo.all()
  end

  def current_tenants_query(date) do
    from(
      unit in Unit,
      join: tenancy in assoc(unit, :tenancies),
      join: tenant in assoc(tenancy, :tenant),
      where: tenancy.start_date <= ^date,
      where: is_nil(tenancy.actual_move_out) or tenancy.actual_move_out > ^date,
      select: tenant
    )
  end

  def tenant_search(admin, term) do
    from(
      t in @schema,
      join: tenancies in assoc(t, :tenancies),
      join: unit in assoc(tenancies, :unit),
      join: p in assoc(unit, :property),
      left_join: i in assoc(p, :icon_url),
      where: p.id in ^admin.property_ids,
      where:
        ilike(t.email, ^"%#{term}%") or
          ilike(fragment("upper(? ||  ' ' || ?)", t.first_name, t.last_name), ^"%#{term}%"),
      preload: ^@preloads
    )
    |> Repo.all(prefix: admin.client_schema)
    |> map_data_for_search()
  end

  def revoke_autopay(%Tenant{aggregate: true, account: %{autopay: %Autopay{} = autopay}}) do
    autopay
    |> Autopay.changeset(%{active: false})
    |> Repo.update()
  end

  def revoke_autopay(%Tenant{aggregate: true}) do
    {:ok, :nothing_happened}
  end

  # ------------------ Private  ---------------------------
  defp map_data_for_search(tenants) do
    tenants
    |> Enum.map(fn t ->
      if tenancy = get_tenancy(t.tenancies) do
        %{
          type: "tenants",
          name: "#{t.first_name} #{t.last_name}",
          id: tenancy.unit.id,
          tenancy_id: tenancy.id,
          unit: tenancy.unit.number,
          property: tenancy.unit.property.name,
          icon: icon_url(tenancy.unit.property.icon_url)
        }
      else
        nil
      end
    end)
    |> Enum.reject(fn tenant -> is_nil(tenant) end)
  end

  defp get_tenancy([head | _] = _tenancies), do: head

  defp icon_url(nil), do: nil

  defp icon_url(icon_url), do: icon_url.url
end
