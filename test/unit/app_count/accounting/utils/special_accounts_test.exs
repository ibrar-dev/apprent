defmodule AppCount.Accounting.Utils.SpecialAccountsTest do
  use AppCount.DataCase
  alias AppCount.Accounting.SpecialAccounts
  alias AppCount.Repo

  def delete_all() do
    AppCount.Ledgers.ChargeCode |> Repo.delete_all()
    AppCount.Accounting.Account |> Repo.delete_all()
  end

  test "get_account works" do
    assert SpecialAccounts.get_account(:rent).name == "Rent"
    assert SpecialAccounts.get_charge_code(:rent).code == "rent"
    assert SpecialAccounts.get_account(:nsf_fees).name == "NSF Fees Income"
    assert SpecialAccounts.get_charge_code(:nsf_fees).code == "nsf"
  end

  test "get_charge_code" do
    delete_all()
    assert SpecialAccounts.get_charge_code(:rent).id

    assert %AppCount.Ledgers.ChargeCode{
             account_id: _account_id,
             code: "rent",
             is_default: true,
             name: "Rent"
           } = SpecialAccounts.get_charge_code(:rent)
  end

  test "get_account" do
    delete_all()
    assert SpecialAccounts.get_account(:rent).id

    assert %AppCount.Accounting.Account{
             description: nil,
             external_id: nil,
             id: _id,
             is_balance: true,
             is_cash: false,
             is_credit: true,
             is_payable: false,
             name: "Rent",
             num: nil,
             source_id: nil
           } = SpecialAccounts.get_account(:rent)
  end
end
