defmodule AppCount.Ledgers.CustomerLedgerRepoTest do
  use AppCount.DataCase
  alias AppCount.Ledgers.CustomerLedgerRepo
  alias AppCount.Core.ClientSchema
  @moduletag :customer_ledger_repo

  def decimal_eq(dec, amount) do
    Decimal.equal?(dec, Decimal.new(amount))
  end

  setup do
    ledger = insert(:customer_ledger)
    {:ok, ledger: ledger}
  end

  test "get correct balance for ledger when empty", %{ledger: ledger} do
    assert decimal_eq(CustomerLedgerRepo.ledger_balance(ClientSchema.new("dasmen", ledger.id)), 0)
  end

  test "get correct balance for ledger when charges exist", %{ledger: ledger} do
    insert(:bill, customer_ledger: ledger, amount: 1200)
    insert(:bill, customer_ledger: ledger, amount: 300)

    assert decimal_eq(
             CustomerLedgerRepo.ledger_balance(ClientSchema.new("dasmen", ledger.id)),
             1500
           )
  end

  test "get correct balance for ledger when charges and payments exist", %{ledger: ledger} do
    insert(:bill, customer_ledger: ledger, amount: 1200)
    insert(:bill, customer_ledger: ledger, amount: 300)
    insert(:payment, customer_ledger: ledger, amount: 750)
    insert(:payment, customer_ledger: ledger, amount: 150)

    assert decimal_eq(
             CustomerLedgerRepo.ledger_balance(ClientSchema.new("dasmen", ledger.id)),
             600
           )

    insert(:payment, customer_ledger: ledger, amount: 800)

    assert decimal_eq(
             CustomerLedgerRepo.ledger_balance(ClientSchema.new("dasmen", ledger.id)),
             -200
           )
  end
end
