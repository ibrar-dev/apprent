defmodule AppCount.Ledgers.PaymentNSFsTest do
  use AppCount.DataCase
  import AppCount.LeasingHelper
  alias AppCount.Ledgers.Payment
  alias AppCount.Ledgers.Charge
  alias AppCount.Ledgers.Utils.PaymentNSFs
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema
  @moduletag :payment_nsfs

  setup do
    t = insert(:tenant)
    start = %Date{year: 2019, day: 1, month: 1}
    end_date = %Date{year: 2020, day: 1, month: 1}
    charges = [Rent: 500, Pet: 10, Something: 15]
    insert_lease(%{start_date: start, end_date: end_date, charges: charges, tenants: [t]})
    {:ok, ins, 0} = DateTime.from_iso8601("2019-01-02T23:50:07Z")
    p = insert(:payment, tenant: t, inserted_at: ins)

    {:ok, payment: p}
  end

  test "create_nsf works", %{payment: payment} do
    PaymentNSFs.create_nsf(
      ClientSchema.new("dasmen", %{
        "nsf_id" => payment.id,
        "customer_ledger_id" => payment.customer_ledger_id,
        "bill_date" => "2019-01-15",
        "description" => "Insufficient Funds"
      })
    )

    assert Repo.get_by(
             Charge,
             bill_date: "2019-01-15",
             nsf_id: payment.id,
             customer_ledger_id: payment.customer_ledger_id,
             amount: payment.amount
           )

    assert Repo.get(Payment, payment.id).status == "nsf"
  end
end
