defmodule AppCount.Leasing.CreateRenewalTest do
  use AppCount.DataCase
  alias AppCount.Leasing.LeaseRepo
  alias AppCount.Leasing.Utils.CreateRenewal
  alias AppCount.Core.ClientSchema

  @moduletag :leasing_create_renewal

  test "renewal creation" do
    original = insert(:leasing_lease)
    renewal_date = Timex.shift(original.end_date, days: 1)
    rent_account = AppCount.Accounting.SpecialAccounts.get_account(:rent)
    rent_cc_id = insert(:charge_code, code: "rent", account: rent_account).id

    renewal_params = %{
      "lease_id" => original.id,
      "start_date" => renewal_date,
      "end_date" => Timex.shift(renewal_date, years: 1),
      "date" => renewal_date,
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
    CreateRenewal.create_renewal(ClientSchema.new("dasmen", renewal_params))

    renewal =
      LeaseRepo.get_by(date: renewal_date)
      |> Repo.preload(:charges)

    assert renewal.start_date == renewal_date
    assert renewal.end_date == Timex.shift(renewal_date, years: 1)
    rent_charge = Enum.find(renewal.charges, &(&1.charge_code_id == rent_cc_id))
    assert Decimal.to_integer(rent_charge.amount) == 5_000
    other_charge = Enum.find(renewal.charges, &(&1.charge_code_id != rent_cc_id))
    assert Decimal.to_integer(other_charge.amount) == 50
    assert renewal.customer_ledger_id == original.customer_ledger_id
    assert renewal.unit_id == original.unit_id
  end
end
