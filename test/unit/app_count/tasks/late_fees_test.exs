# currently deprecated and unused, it's being kept around commented out in order to port to the new leasing system

# defmodule AppCount.LateFeesTaskTest do
#  use AppCount.DataCase
#  use AppCount.Decimal
#  import AppCount.TimeCop
#  import AppCount.LeaseHelper
#  alias AppCount.Properties.PropertyRepo
#  alias AppCount.Accounting.Receipts
#  alias AppCount.Tasks.Workers.LateFees, as: Subject
#
#  @moduletag :late_fees
#
#  @start_date %Date{year: 2018, month: 6, day: 1}
#  @end_date %Date{year: 2019, month: 5, day: 31}
#  @charges [rent: 850, Admin: 90, Pet: 30, Water: 12]
#  @charges_total Enum.reduce(@charges, 0, fn {_, v}, sum -> sum + v end)
#
#  def run_with(%{settings: settings, days: days} = p) do
#    date = Timex.shift(@start_date, days: days)
#    tenants = [insert(:tenant), insert(:tenant)]
#    unit = insert(:unit)
#
#    lease =
#      insert_lease(%{
#        charges: @charges,
#        start_date: @start_date,
#        end_date: @end_date,
#        tenants: tenants,
#        unit: unit
#      })
#
#    insert_lease(%{
#      charges: @charges,
#      start_date: Timex.shift(@start_date, years: -1),
#      end_date: Timex.shift(@end_date, years: -1),
#      renewal_id: lease.id,
#      tenants: tenants,
#      unit: unit
#    })
#
#    freeze date do
#      AppCount.Tasks.Workers.Charges.perform()
#    end
#
#    Enum.each(
#      0..11,
#      fn num ->
#        tenant = Enum.at(tenants, Integer.mod(num, 2))
#
#        ts =
#          Timex.shift(@start_date, months: num - 12)
#          |> Timex.to_datetime()
#
#        insert(:payment, %{tenant_id: tenant.id, amount: 982, inserted_at: ts})
#      end
#    )
#
#    tenant_id = hd(lease.tenants).id
#
#    if Map.get(p, :payments) do
#      p.payments
#      |> Enum.each(
#        &insert(:payment, %{tenant_id: tenant_id, amount: &1.amount, inserted_at: &1.inserted_at})
#      )
#    end
#
#    _property = PropertyRepo.update_property_settings(lease.unit.property, settings)
#
#    Enum.each(
#      Repo.all(AppCount.Ledgers.Payment),
#      &Receipts.PaymentLease.match_payment_to_lease(&1)
#    )
#
#    Enum.each(Repo.all(AppCount.Leases.Lease), &Receipts.receipts(&1.id))
#
#    freeze date do
#      Subject.perform()
#    end
#
#    bills =
#      Repo.preload(lease, bills: :charge_code)
#      |> Map.get(:bills)
#
#    total = Enum.reduce(bills, 0, &(&2 + &1.amount))
#    [bills, total]
#  end
#
#  setup do
#    Repo.delete_all(AppCount.Leases.Lease)
#    {:ok, []}
#  end
#
#  @tag :slow
#  test "charges flat late fees only after grace period" do
#    late_fee_amount = 50
#
#    [bills, _] =
#      run_with(%{
#        days: 9,
#        settings: %{
#          late_fee_amount: late_fee_amount,
#          late_fee_threshold: 10,
#          grace_period: 10
#        }
#      })
#
#    refute Enum.any?(bills, &(&1.charge_code.code == "late"))
#
#    [bills, total] =
#      run_with(%{
#        days: 11,
#        settings: %{
#          late_fee_amount: late_fee_amount,
#          late_fee_threshold: 10,
#          grace_period: 10
#        }
#      })
#
#    assert length(bills) == 5
#
#    assert Enum.any?(
#             bills,
#             &(&1.charge_code.code == "late" && Decimal.to_float(&1.amount) == late_fee_amount)
#           )
#
#    assert total == @charges_total + late_fee_amount
#  end
#
#  test "charges percentage late fees" do
#    [bills, total] =
#      run_with(%{
#        days: 11,
#        settings: %{
#          late_fee_amount: 5,
#          late_fee_threshold: 10,
#          grace_period: 10,
#          late_fee_type: "%"
#        }
#      })
#
#    late_fee = 0.05 * @charges[:Rent]
#
#    late_fee_charge_code = AppCount.Ledgers.Utils.SpecialChargeCodes.get_charge_code(:late_fees)
#
#    assert Enum.any?(
#             bills,
#             &(&1.charge_code.code == "late" && Decimal.to_float(&1.amount) == late_fee)
#           )
#
#    assert length(bills) == 5
#    assert total == @charges_total + late_fee
#  end
#
#  test "honors grace period" do
#    [bills, total] =
#      run_with(%{
#        days: 11,
#        settings: %{
#          late_fee_amount: 5,
#          late_fee_threshold: 10,
#          grace_period: 12
#        }
#      })
#
#    refute Enum.any?(bills, &(&1.charge_code.code == "late"))
#    assert length(bills) == 4
#    assert total == @charges_total
#  end
#
#  @tag :slow
#  test "honors threshold" do
#    [bills, total] =
#      run_with(%{
#        days: 11,
#        settings: %{
#          late_fee_amount: 50,
#          late_fee_threshold: 1000,
#          grace_period: 10
#        }
#      })
#
#    refute Enum.any?(bills, &(&1.charge_code.code == "late"))
#    assert length(bills) == 4
#    assert total == @charges_total
#  end
#
#  @tag :slow
#  test "processes payments" do
#    ts =
#      @start_date
#      |> Timex.to_datetime()
#      |> Timex.shift(days: 1)
#
#    [bills, total] =
#      run_with(%{
#        days: 11,
#        settings: %{
#          late_fee_amount: 50,
#          late_fee_threshold: 10,
#          grace_period: 10
#        },
#        payments: [
#          %{amount: 800, inserted_at: ts},
#          %{amount: 800, inserted_at: Timex.shift(ts, days: 2)}
#        ]
#      })
#
#    refute Enum.any?(bills, &(&1.charge_code.code == "late"))
#    assert length(bills) == 4
#    assert total == @charges_total
#  end
#
#  test "charges late fees when payment insufficient" do
#    ts =
#      @start_date
#      |> Timex.to_datetime()
#      |> Timex.shift(days: -5)
#
#    late_fee_amount = 50
#
#    [bills, total] =
#      run_with(%{
#        days: 11,
#        settings: %{
#          late_fee_amount: late_fee_amount,
#          late_fee_threshold: 10,
#          grace_period: 10
#        },
#        payments: [%{amount: 800, inserted_at: ts}]
#      })
#
#    assert Enum.any?(
#             bills,
#             &(&1.charge_code.code == "late" && Decimal.to_float(&1.amount) == late_fee_amount)
#           )
#
#    assert length(bills) == 5
#    assert total == @charges_total + late_fee_amount
#  end
#
#  @tag :slow
#  test "charges late fees and does not double charge" do
#    late_fee_amount = 50
#
#    [bills, _] =
#      run_with(%{
#        days: 10,
#        settings: %{
#          late_fee_amount: late_fee_amount,
#          late_fee_threshold: 10,
#          grace_period: 10,
#          daily_late_fee_addition: 10
#        },
#        payments: []
#      })
#
#    Enum.each(
#      11..15,
#      fn num ->
#        freeze Timex.shift(@start_date, days: num) do
#          Subject.perform()
#        end
#      end
#    )
#
#    lease_id = hd(bills).lease_id
#
#    late_fees =
#      Repo.all(AppCount.Ledgers.Charge)
#      |> Repo.preload(:charge_code)
#      |> Enum.filter(&(&1.charge_code.code == "late" && &1.lease_id == lease_id))
#
#    assert Enum.any?(late_fees, &(Decimal.to_float(&1.amount) == late_fee_amount))
#    assert length(late_fees) == 6
#    assert Enum.reduce(late_fees, 0, &(&1.amount + &2)) == late_fee_amount + 50
#
#    freeze Timex.shift(@start_date, days: 15) do
#      Subject.perform()
#    end
#
#    late_fees =
#      Repo.all(AppCount.Ledgers.Charge)
#      |> Repo.preload(:charge_code)
#      |> Enum.filter(&(&1.charge_code.code == "late" && &1.lease_id == lease_id))
#
#    assert length(late_fees) == 6
#
#    freeze Timex.shift(@start_date, days: 16) do
#      Subject.perform()
#    end
#
#    freeze Timex.shift(@start_date, days: 17) do
#      Subject.perform()
#    end
#
#    late_fees =
#      Repo.all(AppCount.Ledgers.Charge)
#      |> Repo.preload(:charge_code)
#      |> Enum.filter(&(&1.charge_code.code == "late" && &1.lease_id == lease_id))
#
#    assert Enum.any?(late_fees, &(Decimal.to_float(&1.amount) == late_fee_amount))
#    assert length(late_fees) == 8
#    assert Enum.reduce(late_fees, 0, &(&1.amount + &2)) == late_fee_amount + 70
#  end
# end
