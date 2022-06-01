defmodule AppCount.Leasing.MonthlyCharges.Data do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Tenants.Tenancy
  alias AppCount.Leasing.Charge
  alias AppCount.Leasing.Lease
  alias AppCount.Ledgers.Utils.SpecialChargeCodes
  alias AppCount.Core.ClientSchema

  def get_data(
        %ClientSchema{
          name: client_schema,
          attrs: current_date
        },
        current_month_start
      )
      when is_binary(client_schema) do
    build_query(current_date, current_month_start)
    |> Repo.all(prefix: client_schema)
  end

  def build_query(current_date, current_month_start) do
    current_leases_query(current_date)
    |> mark_is_section_8
    |> join_renewal_date
    |> attach_property_settings
    |> join_charges
    |> check_already_billed(current_month_start)
    |> check_is_not_past_to_date(current_date)
    |> select_fields()
  end

  def current_leases_query(current_date) do
    from(
      tenancy in Tenancy,
      join: lease in Lease,
      on: tenancy.customer_ledger_id == lease.customer_ledger_id,
      where: lease.start_date <= ^current_date,
      where: is_nil(tenancy.actual_move_out) or tenancy.actual_move_out > ^current_date,
      select: %{
        id:
          first_value(lease.id)
          |> over(
            partition_by: [lease.customer_ledger_id],
            order_by: [
              desc: lease.start_date
            ]
          ),
        start_date: lease.start_date,
        end_date: lease.end_date,
        unit_id: lease.unit_id,
        customer_ledger_id: lease.customer_ledger_id
      }
    )
  end

  def join_renewal_date(query) do
    query
    |> join(:left, [_tenancy, lease], renewal in Lease,
      on:
        renewal.customer_ledger_id == lease.customer_ledger_id and
          renewal.start_date > lease.end_date
    )
    |> select_merge([_tenancy, _lease, _hap_charge, renewal], %{renewal: renewal.start_date})
  end

  def mark_is_section_8(query) do
    hap_rent_charge_code = SpecialChargeCodes.get_charge_code(:hap_rent).id

    query
    |> join(:left, [_tenancy, lease], hap_charge in assoc(lease, :charges),
      on: hap_charge.lease_id == lease.id and hap_charge.charge_code_id == ^hap_rent_charge_code
    )
    |> select_merge([_tenancy, _lease, hap_charge], %{section_8: hap_charge.id})
  end

  def attach_property_settings(query) do
    query
    |> join(:inner, [_tenancy, lease], unit in assoc(lease, :unit))
    |> join(
      :inner,
      [_tenancy, _lease, _charge, _renewal, unit],
      property in assoc(unit, :property)
    )
    |> join(
      :inner,
      [_tenancy, _lease, _charge, _renewal, _unit, property],
      setting in assoc(property, :setting)
    )
    |> select_merge([_tenancy, _lease, _charge, _renewal, _unit, _property, setting], %{
      mtm_fee: setting.mtm_fee
    })
  end

  def join_charges(query) do
    from(
      lease_data in subquery(query),
      join: charge in Charge,
      on: charge.lease_id == lease_data.id,
      join: code in assoc(charge, :charge_code),
      distinct: charge.id
    )
  end

  defp check_already_billed(query, current_month_start) do
    # we will never bill the same charge twice in one month
    where(
      query,
      [_, charge],
      is_nil(charge.last_bill_date) or charge.last_bill_date < ^current_month_start
    )
  end

  defp check_is_not_past_to_date(query, current_date) do
    where(query, [_, charge], is_nil(charge.to_date) or charge.to_date >= ^current_date)
  end

  defp select_fields(query) do
    rent_charge_code = SpecialChargeCodes.get_charge_code(:rent).id

    query
    |> select([lease_data, charge, code], %{
      charge_id: charge.id,
      charge_code_id: charge.charge_code_id,
      is_rent_charge: charge.charge_code_id == ^rent_charge_code,
      code: code.code,
      from: charge.from_date,
      to: charge.to_date,
      amount: type(charge.amount, :float),
      lease_start: lease_data.start_date,
      end_date: lease_data.end_date,
      section_8: lease_data.section_8,
      customer_ledger_id: lease_data.customer_ledger_id,
      unit_id: lease_data.unit_id,
      renewal: lease_data.renewal,
      mtm_fee: lease_data.mtm_fee
    })
  end
end
