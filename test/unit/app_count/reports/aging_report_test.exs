defmodule AppCount.Reports.AgingReportTest do
  use AppCount.DataCase
  alias AppCount.Reports
  @moduletag :aging_reports

  @sample_date %Date{year: 2019, month: 1, day: 1}

  setup do
    property = insert(:property)
    invoice1 = insert(:invoice, date: @sample_date)
    invoice2 = insert(:invoice, date: Map.put(@sample_date, :day, 10))

    invoicing1 = insert(:invoicing, invoice: invoice1, amount: 250, property: property)
    insert(:invoicing, invoice: invoice2, amount: 250, property: property)
    invoicing2 = insert(:invoicing, invoice: invoice2, amount: 250, property: property)

    insert(:invoice_payment, invoicing: invoicing1, amount: 200, post_month: @sample_date)
    insert(:invoice_payment, invoicing: invoicing2, amount: 100, post_month: @sample_date)
    insert(:invoice_payment, invoicing: invoicing2, amount: 50, post_month: @sample_date)

    {:ok,
     [
       property: property,
       invoice1: invoice1,
       invoice2: invoice2,
       admin: admin_with_access([property.id])
     ]}
  end

  test "aging report works", %{property: property, invoice1: invoice1, admin: admin} do
    result = Reports.aging_report(admin, property.id)
    assert length(result) == 2

    Enum.each(
      result,
      fn payee ->
        if payee.payee == invoice1.payee.name do
          assert length(payee.invoices) == 1
          assert hd(payee.invoices)["amount"] == 50
        else
          assert length(payee.invoices) == 2
          assert Enum.map(payee.invoices, & &1["amount"]) == [250, 100]
        end
      end
    )
  end
end
