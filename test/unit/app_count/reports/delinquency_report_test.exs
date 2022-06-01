defmodule AppCount.Reports.DelinquencyReportTest do
  use AppCount.DataCase
  alias AppCount.Reports
  alias AppCount.Accounting.Receipts
  import AppCount.LeaseHelper
  import AppCount.TimeCop
  @moduletag :deliquency_reports

  @first_start_date %Date{year: 2017, month: 6, day: 1}
  @first_end_date %Date{year: 2018, month: 5, day: 31}
  @start_date %Date{year: 2018, month: 6, day: 1}
  @end_date %Date{year: 2019, month: 5, day: 31}
  @charges [rent: 900, Admin: 100, Pet: 50, Concession: -50]

  setup do
    property = insert(:property)
    tenants = [insert(:tenant), insert(:tenant)]

    insert_lease(%{
      start_date: @first_start_date,
      end_date: @first_end_date,
      charges: @charges,
      tenants: tenants,
      actual_move_in: @first_start_date,
      actual_move_out: @first_end_date,
      unit: insert(:unit, property: property)
    })

    lease =
      insert_lease(%{
        start_date: @start_date,
        end_date: @end_date,
        charges: @charges,
        tenants: tenants,
        actual_move_in: @start_date,
        unit: insert(:unit, property: property)
      })

    freeze @end_date do
      AppCount.Tasks.Workers.Charges.perform()
    end

    -12..10
    |> Enum.each(fn num ->
      date = Timex.shift(@start_date, months: num)

      payment_date =
        Timex.shift(date, days: 1)
        |> Timex.to_datetime()

      tenant = Enum.at(tenants, Integer.mod(num, 2))

      insert(:payment, inserted_at: payment_date, post_month: date, tenant: tenant, amount: 1000)
      |> Receipts.PaymentLease.match_payment_to_lease()
    end)

    {:ok, property: property, lease: lease}
  end

  @tag :slow
  test "delinquency report works", %{property: property, lease: lease} do
    Receipts.receipts(lease.id)
    result = Reports.delinquency_report(property.id, "2019-05-31")
    assert length(result) == 1
    without_breakdown = Map.delete(hd(result), :charges)

    tenant = Enum.find(lease.tenants, &(without_breakdown.tenant_id == &1.id))

    assert without_breakdown ==
             %{
               tenant_id: tenant.id,
               tenant: "#{tenant.first_name} #{tenant.last_name}",
               unit: lease.unit.number,
               status: "current",
               owed: 1.0e3,
               memos: []
             }

    assert Enum.map(
             result,
             fn r ->
               Enum.map(
                 r.charges,
                 fn charge ->
                   if charge["days_late"] == 30, do: charge["amount"], else: 0
                 end
               )
               |> Enum.sum()
             end
           ) == [1050]
  end
end
