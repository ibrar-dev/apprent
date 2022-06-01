defmodule AppCount.Leasing.CreateNewTenancyTest do
  use AppCount.DataCase
  alias AppCount.Leasing.LeaseRepo
  alias AppCount.Leasing.Utils.CreateNewTenancy
  alias AppCount.Tenants.TenancyRepo
  alias AppCount.Ledgers.CustomerLedgerRepo
  alias AppCount.Core.ClientSchema

  @moduletag :leasing_create_new_tenancy

  test "transfer creation" do
    tenancy = insert(:tenancy)
    original = insert(:leasing_lease)
    transfer_date = Timex.shift(original.end_date, days: 1)
    rent_account = AppCount.Accounting.SpecialAccounts.get_account(:rent)
    rent_cc_id = insert(:charge_code, code: "rent", account: rent_account).id
    new_unit = insert(:unit)

    transfer_params = %{
      "tenant_id" => tenancy.tenant_id,
      "unit_id" => new_unit.id,
      "start_date" => transfer_date,
      "end_date" => Timex.shift(transfer_date, years: 1),
      "date" => transfer_date,
      "charges" => [
        %{
          "amount" => 5_000,
          "charge_code_id" => rent_cc_id
        },
        %{
          "amount" => 50,
          "charge_code_id" => insert(:charge_code).id
        }
      ]
    }

    # When
    {:ok, _} = CreateNewTenancy.create_new_tenancy(ClientSchema.new("dasmen", transfer_params))

    new_lease =
      LeaseRepo.get_by(date: transfer_date)
      |> Repo.preload(:charges)

    new_tenancy = TenancyRepo.get_by(start_date: transfer_date)

    assert new_lease.start_date == transfer_date
    assert new_lease.end_date == Timex.shift(transfer_date, years: 1)

    rent_charge = Enum.find(new_lease.charges, &(&1.charge_code_id == rent_cc_id))
    assert Decimal.to_integer(rent_charge.amount) == 5_000
    other_charge = Enum.find(new_lease.charges, &(&1.charge_code_id != rent_cc_id))
    assert Decimal.to_integer(other_charge.amount) == 50

    assert new_tenancy.customer_ledger_id == new_lease.customer_ledger_id

    assert CustomerLedgerRepo.get(new_tenancy.customer_ledger_id).property_id ==
             new_unit.property_id
  end
end
