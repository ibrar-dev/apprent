defmodule AppCount.ShortCodes.Tenants do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Core.Clock
  alias AppCount.Tenants.Utils.Tenants
  alias AppCount.Tenants.Tenancy
  alias AppCount.Core.ClientSchema

  # You should always pass in the tenancy_id.
  def parse_short_codes(body, %{tenant_id: tenancy_id}) do
    tenant_id_from_tenancy(tenancy_id)
    |> case do
      nil ->
        nil

      tenancy ->
        AppCount.ShortCodes.Parser.parse_html(body, fn code ->
          replace_short_code(code, tenancy.tenant_id)
        end)
    end
  end

  defp tenant_id_from_tenancy(tenancy_id) when is_binary(tenancy_id),
    do: tenant_id_from_tenancy(String.to_integer(tenancy_id))

  defp tenant_id_from_tenancy(tenancy_id) do
    Repo.get(Tenancy, tenancy_id)
  end

  ##### GENERAL #####
  defp replace_short_code("CURRENT_DATE", _id), do: AppCount.current_date()

  defp replace_short_code("START_CURRENT_MONTH", _id) do
    AppCount.current_date()
    |> Timex.beginning_of_month()
  end

  defp replace_short_code("CURRENT_DATE_TIME", _id), do: Clock.now() |> Clock.to_nyc()

  ##### ^GENERAL #####

  ##### RESIDENT #####
  defp replace_short_code("FULL_NAME", id) do
    from(
      t in AppCount.Tenants.Tenant,
      where: t.id == ^id,
      select: fragment("? || ' ' || ?", t.first_name, t.last_name),
      limit: 1
    )
    |> Repo.one()
  end

  defp replace_short_code("FIRST_NAME", id) do
    from(
      t in AppCount.Tenants.Tenant,
      where: t.id == ^id,
      select: t.first_name,
      limit: 1
    )
    |> Repo.one()
  end

  defp replace_short_code("LAST_NAME", id) do
    from(
      t in AppCount.Tenants.Tenant,
      where: t.id == ^id,
      select: t.last_name,
      limit: 1
    )
    |> Repo.one()
  end

  defp replace_short_code("EMAIL", id) do
    from(
      t in AppCount.Tenants.Tenant,
      where: t.id == ^id,
      select: t.email,
      limit: 1
    )
    |> Repo.one()
  end

  defp replace_short_code("MONEYGRAM_ACCOUNT", tenant_id) do
    property = Tenants.property_for(tenant_id)
    "#{String.pad_leading("#{property.id}", 4, "0000")}#{tenant_id}"
  end

  ##### ^RESIDENT #####

  ##### PROPERTY #####
  defp replace_short_code("PROPERTY_NAME", id) do
    Tenants.property_for(id).name
  end

  defp replace_short_code("PROPERTY_ADDRESS", id) do
    Tenants.property_for(id).address["street"]
  end

  defp replace_short_code("PROPERTY_ADDRESS_FULL", id) do
    property = Tenants.property_for(id)

    "#{property.address["street"]}, #{property.address["city"]}, #{property.address["state"]} #{
      property.address["zip"]
    }"
  end

  defp replace_short_code("PROPERTY_ADDRESS_REMAINING", id) do
    property = Tenants.property_for(id)
    "#{property.address["city"]}, #{property.address["state"]} #{property.address["zip"]}"
  end

  defp replace_short_code("PROPERTY_WEBSITE", id) do
    Tenants.property_for(id).website
  end

  defp replace_short_code("PROPERTY_PHONE", id) do
    Tenants.property_for(id).phone
  end

  defp replace_short_code("PROPERTY_GROUP_EMAIL", id) do
    Tenants.property_for(id).group_email
  end

  defp replace_short_code("PROPERTY_APP_FEE", id) do
    property = Tenants.property_for(id)
    setting = PropertyRepo.property_settings(ClientSchema.new("dasmen", property))
    setting.application_fee
  end

  defp replace_short_code("PROPERTY_ADMIN_FEE", id) do
    property = Tenants.property_for(id)
    setting = PropertyRepo.property_settings(ClientSchema.new("dasmen", property))
    setting.admin_fee
  end

  defp replace_short_code("PROPERTY_NOTICE_PERIOD", id) do
    property = Tenants.property_for(id)
    setting = PropertyRepo.property_settings(ClientSchema.new("dasmen", property))
    setting.notice_period
  end

  defp replace_short_code("PROPERTY_GRACE_PERIOD", id) do
    property = Tenants.property_for(id)
    setting = PropertyRepo.property_settings(ClientSchema.new("dasmen", property))
    setting.grace_period
  end

  defp replace_short_code("PROPERTY_LATE_FEE", id) do
    property = Tenants.property_for(id)
    setting = PropertyRepo.property_settings(ClientSchema.new("dasmen", property))
    setting.late_fee_amount
  end

  ##### ^PROPERTY #####

  ##### UNIT #####
  defp replace_short_code("UNIT_NUMBER", id) do
    %{unit_id: unit_id} = AppCount.Accounts.unit_info(id)
    AppCount.Repo.get(AppCount.Properties.Unit, unit_id).number
  end

  defp replace_short_code("UNIT_ADDRESS", id) do
    %{unit_id: unit_id} = AppCount.Accounts.unit_info(id)
    AppCount.Repo.get(AppCount.Properties.Unit, unit_id).address["street"]
  end

  defp replace_short_code("UNIT_MARKET_RENT", id) do
    %{unit_id: unit_id} = AppCount.Accounts.unit_info(id)
    AppCount.Properties.unit_rent(%{id: unit_id})
  end

  ##### ^UNIT #####

  ##### LEASE #####
  defp replace_short_code("RECURRING_CHARGES", id) do
    Tenants.get_tenants_charges(id)
  end

  defp replace_short_code("CURRENT_BALANCE", id) do
    AppCount.Accounts.user_balance(ClientSchema.new("dasmen", id))
    |> Enum.reduce(Decimal.new(0), &Decimal.add(&2, &1.balance))
  end

  defp replace_short_code("LEASE_START", id) do
    from(
      o in AppCount.Properties.Occupancy,
      join: l in assoc(o, :lease),
      where: o.tenant_id == ^id,
      where: is_nil(l.actual_move_out),
      select: l.start_date,
      limit: 1
    )
    |> Repo.one()
  end

  defp replace_short_code("LEASE_END", id) do
    from(
      o in AppCount.Properties.Occupancy,
      join: l in assoc(o, :lease),
      where: o.tenant_id == ^id,
      where: is_nil(l.actual_move_out),
      select: l.end_date,
      limit: 1
    )
    |> Repo.one()
  end

  ##### ^LEASE #####

  ##### ACCOUNT #####
  defp replace_short_code("REWARDS_BALANCE", id) do
    AppCount.Rewards.tenant_points(id)
  end

  ##### ^ACCOUNT #####

  ##### WHEN IT NO LONGER MATCHES #####
  defp replace_short_code(code, _), do: code
end
