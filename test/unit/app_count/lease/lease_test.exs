defmodule AppCount.LeaseTest do
  use AppCount.DataCase
  alias AppCount.Leases
  alias AppCount.Repo
  alias AppCount.Leases.Lease
  alias AppCount.Core.ClientSchema

  def create_lease(params) do
    %Lease{}
    |> Lease.changeset(params)
    |> Repo.insert()
  end

  setup do
    {:ok, [lease: insert(:lease, deposit_amount: 500)]}
  end

  test "create_lease works", %{lease: lease} do
    tenant_id = hd(lease.tenants).id

    base_params = %{
      "start_date" => Timex.shift(lease.end_date, days: 1),
      "end_date" => Timex.shift(lease.end_date, days: 366),
      "unit_id" => lease.unit_id,
      "tenant_id" => tenant_id,
      "deposit_amount" => lease.deposit_amount,
      "charges" => [%{"charge_code_id" => insert(:charge_code).id, "amount" => 950}]
    }

    {:ok, %{lease: renewal} = result} =
      Leases.create_lease(ClientSchema.new("dasmen", base_params))

    refute result.sec_dep_charge
    assert Decimal.equal?(hd(result.charges).amount, Decimal.new(950))

    tenant =
      Repo.preload(renewal, :tenants)
      |> Map.get(:tenants)
      |> hd

    assert tenant.id == tenant_id
    assert Repo.get(Lease, lease.id).renewal_id == renewal.id

    Repo.delete(renewal)

    {:ok, %{lease: non_renewal} = result} =
      ClientSchema.new("dasmen", Map.put(base_params, "tenant_id", insert(:tenant).id))
      |> Leases.create_lease()

    assert result.sec_dep_charge.amount == lease.deposit_amount
    assert Decimal.equal?(hd(result.charges).amount, Decimal.new(950))
    assert non_renewal.unit_id == lease.unit_id
    assert Repo.get(Lease, lease.id).renewal_id == nil
  end

  test "valid_duration constraint works", %{lease: lease} do
    date =
      AppCount.current_date()
      |> Timex.shift(years: 2)

    tenant_id = hd(lease.tenants).id

    {:error, error} =
      create_lease(%{
        start_date: date,
        end_date: date,
        unit_id: lease.unit_id,
        tenant_id: tenant_id
      })

    assert error.errors[:lease_duration]
  end

  test "overlap constraint works", %{lease: lease} do
    tenant = insert(:tenant)

    start_date =
      lease.end_date
      |> Timex.shift(days: -60)

    {:error, error} =
      %{
        unit_id: lease.unit_id,
        tenant_id: tenant.id,
        start_date: start_date,
        end_date: Timex.shift(start_date, days: 90),
        rent: 500
      }
      |> create_lease

    assert assert error.errors[:lease_term]
  end
end
