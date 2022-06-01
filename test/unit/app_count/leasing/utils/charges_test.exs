defmodule AppCount.Leases.Utils.ChargesTest do
  use AppCount.DataCase
  alias AppCount.Leasing.ChargeRepo
  alias AppCount.Leasing.Utils.Charges
  alias AppCount.Ledgers.Utils.SpecialChargeCodes
  alias AppCount.Core.ClientSchema
  @moduletag :leasing_charges

  setup do
    lease = insert(:leasing_lease)
    rent_cc = SpecialChargeCodes.get_charge_code(:rent)
    rent_charge = insert(:leasing_charge, lease: lease, charge_code: rent_cc)
    other_charge = insert(:leasing_charge, lease: lease)
    lease = Map.put(lease, :charges, [rent_charge, other_charge])

    new_admin = AppCount.UserHelper.new_admin()
    {:ok, lease: lease, admin: new_admin, rent_charge_code: rent_cc}
  end

  test "update_charges with valid attrs", %{lease: lease, admin: admin, rent_charge_code: rent_cc} do
    [updated_charge_id, deleted_charge_id] = Enum.map(lease.charges, & &1.id)
    new_charge_code = insert(:charge_code)

    attrs = [
      %{
        amount: 100,
        charge_code_id: new_charge_code.id
      },
      %{
        id: updated_charge_id,
        amount: 1_000,
        charge_code_id: rent_cc.id
      }
    ]

    {:ok, _} = Charges.update_charges(ClientSchema.new("dasmen", admin), lease.id, attrs)

    refute ChargeRepo.get(deleted_charge_id)

    updated = ChargeRepo.get(updated_charge_id)

    assert Decimal.to_integer(updated.amount) == 1_000
    new_charge = ChargeRepo.get_by(charge_code_id: new_charge_code.id)
    assert Decimal.to_integer(new_charge.amount) == 100
  end

  test "update_charges with no rent charge attrs", %{lease: lease, admin: admin} do
    [updated_charge_id, _] = Enum.map(lease.charges, & &1.id)
    new_charge_code = insert(:charge_code)

    attrs = [
      %{
        amount: 100,
        charge_code_id: new_charge_code.id
      },
      %{
        id: updated_charge_id,
        amount: 1_000,
        charge_code_id: new_charge_code.id
      }
    ]

    assert {:error, "No rent charge"} ==
             Charges.update_charges(ClientSchema.new("dasmen", admin), lease.id, attrs)
  end

  test "update_charges with no open ended rent charge", %{
    lease: lease,
    admin: admin,
    rent_charge_code: rent_cc
  } do
    [updated_charge_id, _] = Enum.map(lease.charges, & &1.id)
    new_charge_code = insert(:charge_code)

    attrs = [
      %{
        amount: 100,
        charge_code_id: new_charge_code.id
      },
      %{
        id: updated_charge_id,
        amount: 1_000,
        charge_code_id: rent_cc.id,
        to_date: Timex.shift(lease.start_date, months: 3)
      }
    ]

    assert {:error, "Must have at least one open ended rent charge"} ==
             Charges.update_charges(ClientSchema.new("dasmen", admin), lease.id, attrs)
  end

  test "update_charges with invalid charge attrs", %{
    lease: lease,
    admin: admin,
    rent_charge_code: rent_cc
  } do
    [updated_charge_id, _] = Enum.map(lease.charges, & &1.id)
    new_charge_code = insert(:charge_code)

    attrs = [
      %{
        charge_code_id: new_charge_code.id
      },
      %{
        id: updated_charge_id,
        amount: 1_000,
        charge_code_id: rent_cc.id
      }
    ]

    {:error, :charge_0, cs, %{}} =
      Charges.update_charges(ClientSchema.new("dasmen", admin), lease.id, attrs)

    assert cs.errors[:amount]
  end
end
