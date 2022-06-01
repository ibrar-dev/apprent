defmodule AppCount.Leasing.MonthlyChargesTest do
  use AppCount.DataCase
  import AppCount.LeasingHelper
  alias AppCount.Leasing.Charge
  alias AppCount.Leasing.ChargeRepo
  alias AppCount.Leasing.MonthlyCharges, as: Subject
  alias AppCount.Ledgers.Utils.SpecialChargeCodes
  alias AppCount.Core.ClientSchema
  use AppCount.Decimal
  @moduletag :leasing_monthly_charges

  @start_date %Date{year: 2017, month: 6, day: 12}
  @end_date %Date{year: 2018, month: 6, day: 12}
  @rent_amount 850

  def sort_by_charge_code(bills) do
    Enum.map(bills, &{String.to_atom(&1.code), &1.amount})
  end

  def mark_as_last_billed(%{charge_id: charge_id}, bill_date) do
    Repo.get(Charge, charge_id)
    |> ChargeRepo.update(%{last_bill_date: bill_date})
  end

  setup do
    charges = [rent: @rent_amount, admin: 90, pet: 30, water: 12]

    %{lease: lease, tenancies: [tenancy]} =
      insert_lease(%{charges: charges, start_date: @start_date, end_date: @end_date})

    {:ok, lease: lease, tenancy: tenancy}
  end

  test "does not charge before lease start" do
    bills =
      ClientSchema.new("dasmen", Timex.shift(@start_date, days: -15))
      |> Subject.perform()

    assert Enum.empty?(bills)
  end

  test "charges prorated rent from day 1" do
    bills =
      ClientSchema.new("dasmen", @start_date)
      |> Subject.perform()
      |> sort_by_charge_code

    assert length(bills) == 4
    assert bills[:water] == 7.6
    assert bills[:pet] == 19
    assert bills[:admin] == 57
    assert bills[:rent] == 538.33
  end

  test "does not charge prorated rent and MTM rent for the month lease ends" do
    bills =
      Subject.perform(ClientSchema.new("dasmen", @end_date))
      |> sort_by_charge_code

    assert length(bills) == 4
    assert bills[:rent] == 850
    assert bills[:water] == 12
    assert bills[:pet] == 30
    assert bills[:admin] == 90
  end

  test "charges full rent and fees from second month" do
    run_date = Timex.shift(@start_date, days: 20)
    bills = Subject.perform(ClientSchema.new("dasmen", run_date))

    amounts =
      bills
      |> sort_by_charge_code

    assert length(bills) == 4
    assert Enum.all?(bills, &(&1.bill_date == ~D[2017-07-01]))
    assert amounts[:water] == 12
    assert amounts[:pet] == 30
    assert amounts[:admin] == 90
    assert amounts[:rent] == 850
  end

  test "does not double bill" do
    date = Timex.shift(@start_date, days: 20)
    bills = Subject.perform(ClientSchema.new("dasmen", date))
    assert length(bills) == 4
    Enum.each(bills, &mark_as_last_billed(&1, ~D[2017-07-01]))
    assert Subject.perform(ClientSchema.new("dasmen", date)) == []
  end

  test "does not charge after move out", %{tenancy: tenancy} do
    AppCount.Tenants.TenancyRepo.update(tenancy, %{actual_move_out: @end_date})
    assert Subject.perform(ClientSchema.new("dasmen", @end_date)) == []
  end

  test "honors to dates", %{lease: lease} do
    last_month = Timex.beginning_of_month(@end_date)

    first_charge =
      Repo.preload(lease, :charges)
      |> Map.get(:charges)
      |> List.first()

    first_charge
    |> ChargeRepo.update(%{to_date: last_month})

    # When
    bills = Subject.perform(ClientSchema.new("dasmen", @end_date))
    assert length(bills) == 3
    refute Enum.find(bills, &(&1.charge_id == first_charge.id))
  end

  test "honors from dates", %{lease: lease} do
    last_month = Timex.beginning_of_month(@end_date)

    first_charge =
      Repo.preload(lease, :charges)
      |> Map.get(:charges)
      |> List.first()

    first_charge
    |> ChargeRepo.update(%{to_date: last_month})

    # When
    bills = Subject.perform(ClientSchema.new("dasmen", @end_date))
    assert length(bills) == 3
    refute Enum.find(bills, &(&1.charge_id == first_charge.id))
  end

  test "charges MTM rent for month after lease end" do
    # in this case unit market rent == 250
    date = Timex.shift(@end_date, months: 1)

    bills =
      Subject.perform(ClientSchema.new("dasmen", date))
      |> sort_by_charge_code()

    assert bills[:water] == 12
    assert bills[:rent] == 250
  end

  test "does not charge MTM rent for section 8 leases after lease end", %{lease: lease} do
    insert(:leasing_charge,
      lease: lease,
      charge_code: SpecialChargeCodes.get_charge_code(:hap_rent),
      amount: 150
    )

    # in this case unit market rent == 250
    date = Timex.shift(@end_date, months: 1)
    # When
    bills =
      Subject.perform(ClientSchema.new("dasmen", date))
      |> sort_by_charge_code()

    assert bills[:water] == 12
    assert bills[:rent] == 850
  end
end
