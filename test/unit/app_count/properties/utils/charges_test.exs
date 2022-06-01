defmodule AppCount.Properties.PropertiesChargeTest do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Accounting
  alias AppCount.Properties
  @moduletag :lease_charges

  setup do
    now = AppCount.current_time()
    start_date = Timex.shift(now, days: -2)
    end_date = Timex.shift(now, days: 365)
    lease = insert_lease(%{charges: [], start_date: start_date, end_date: end_date})
    {:ok, [lease: lease]}
  end

  test "create_charge with validations", %{lease: lease} do
    invalid_start = Timex.shift(lease.start_date, days: -1)
    invalid_end = Timex.shift(lease.end_date, days: 1)

    valid_params = %{
      amount: 500,
      charge_code_id: Accounting.SpecialAccounts.get_charge_code(:rent).id,
      lease_id: lease.id,
      from_date: lease.start_date,
      to_date: lease.end_date
    }

    {:error, e} = Properties.create_charge(%{valid_params | to_date: invalid_end})
    assert e.errors == [to_date: {"cannot be after lease end", []}]
    {:error, e} = Properties.create_charge(%{valid_params | from_date: invalid_start})
    assert e.errors == [from_date: {"cannot be before lease start", []}]
    {:ok, charge} = Properties.create_charge(valid_params)
    assert Decimal.to_float(charge.amount) == 500
    assert charge.lease_id == lease.id
  end

  test "delete_charge", %{lease: lease} do
    charge = insert(:charge, lease: lease)
    Properties.delete_charge(charge.id)
    refute Repo.get(Properties.Charge, charge.id)
  end
end
