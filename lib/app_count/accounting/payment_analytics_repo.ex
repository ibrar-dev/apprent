defmodule AppCount.Accounting.PaymentAnalyticsRepo do
  alias AppCount.Repo
  alias AppCount.Ledgers.Payment
  alias AppCount.Core.DateTimeRange
  alias AppCount.Tenants.TenantRepo
  import Ecto.Query

  # Bad location for this, but thats on Operations.
  def tenants_with_autopay(property_ids, schema) do
    TenantRepo.current_tenants_query(AppCount.current_date())
    |> join(:inner, [_unit, _tenancy, t], a in assoc(t, :account))
    |> join(:inner, [_unit, _tenancy, _tenant, a], autopay in assoc(a, :autopay))
    |> where([_, _, _, _, autopay], autopay.active)
    |> where([unit, _, _, _, _], unit.property_id in ^property_ids)
    |> Repo.all(prefix: schema)
  end

  # Bad location for this, but thats on Operations.
  # Function is meant to get all current tenants that have never logged in.
  # Property -> Unit -> Tenancy -> Tenant -> Account -> Logins
  def tenants_with_no_login(property_ids, schema) do
    TenantRepo.current_tenants_query(AppCount.current_date())
    |> join(:left, [_unit, _tenancy, t], a in assoc(t, :account))
    |> join(:left, [_unit, _tenancy, _tenant, account], l in assoc(account, :logins))
    |> where([_, _, _, _, logins], is_nil(logins))
    |> where([unit, _, _, _, _], unit.property_id in ^property_ids)
    |> Repo.all(prefix: schema)
  end

  # /payment_analytics Chart Data
  def get_payments_in_range(%DateTimeRange{} = date_range, property_ids, schema) do
    payments_in_query(date_range, property_ids)
    |> order_by([_p], asc: :inserted_at)
    |> select([payment], %{
      id: payment.id,
      inserted_at: payment.inserted_at,
      source_type: payment.payment_type,
      amount: payment.amount,
      description: payment.description,
      source: payment.source,
      surcharge: payment.surcharge
    })
    |> Repo.all(prefix: schema)
  end

  defp payments_in_query(
         %AppCount.Core.DateTimeRange{
           from: from,
           to: to
         },
         property_ids
       ) do
    from(
      p in Payment,
      where: p.inserted_at >= ^from,
      where: p.inserted_at <= ^to,
      where: p.property_id in ^property_ids
    )
  end
end
