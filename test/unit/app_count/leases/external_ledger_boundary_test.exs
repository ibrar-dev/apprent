defmodule AppCount.Leases.ExternalLedgerBoundaryTest do
  use AppCount.DataCase
  doctest AppCount.Leases.ExternalLedgerBoundary
  alias AppCount.Leases.ExternalLedgerBoundary

  defmodule ExternalLedgerBoundaryParrot do
    use TestParrot
    #       scope     function   default-returns-value
    parrot(:boundary, :entries, [])
    parrot(:boundary, :save_balance, [])
    parrot(:boundary, :yardi_to_map, [])
  end

  defmodule YardiGatewayParrot do
    use TestParrot
    #       scope     function   default-returns-value
    parrot(:yardi, :get_resident_data, [])
  end

  defmodule ExternalBalanceRepoParrot do
    use TestParrot
    #       scope     function   default-returns-value
    parrot(:repo, :update, {:ok, Decimal.new(0)})
    parrot(:repo, :get_by, %AppCount.Tenants.Tenancy{})
  end

  setup do
    yardi_payment = %Yardi.Response.GetResidentData.Payment{amount: 3}
    yardi_charge = %Yardi.Response.GetResidentData.Charge{amount: 5}
    ~M[yardi_payment, yardi_charge]
  end

  describe "ledger_details/1" do
    test "cable test" do
      # When
      _result = ExternalLedgerBoundary.ledger_details("99", ExternalLedgerBoundaryParrot)

      assert_receive {:entries, "99"}
      assert_receive {:save_balance, [], "99"}
      assert_receive {:yardi_to_map, []}
    end
  end

  describe "entries/1" do
    setup do
      external_id = "999"

      [_builder, property, tenancy] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property(%{external_id: external_id})
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy(%{external_id: external_id})
        |> PropBuilder.get([:property, :tenancy])

      ~M[property, tenancy, external_id]
    end

    test "calls yardi", ~M[_property, _tenancy, external_id] do
      _result = ExternalLedgerBoundary.entries(external_id, YardiGatewayParrot)
      assert_receive {:get_resident_data, "999", "999"}
    end
  end

  describe "save_balance/3" do
    test "no payments" do
      entry_array = []
      result = ExternalLedgerBoundary.save_balance(entry_array, "99", ExternalBalanceRepoParrot)
      decimal_zero = Decimal.new(0)
      assert result == entry_array
      assert_receive {:update, %AppCount.Tenants.Tenancy{}, %{external_balance: ^decimal_zero}}
    end
  end

  describe "balance_as_decimal/3" do
    test "no payments" do
      entry_array = []
      result = ExternalLedgerBoundary.balance_as_decimal(entry_array)
      assert result == Decimal.new(0)
    end

    test "one negative decimal for yardi payments", ~M[yardi_payment] do
      entry_array = [yardi_payment]
      result = ExternalLedgerBoundary.balance_as_decimal(entry_array)
      assert result == Decimal.new(-3)
    end

    test "two payments", ~M[yardi_payment] do
      entry_array = [yardi_payment, yardi_payment]
      result = ExternalLedgerBoundary.balance_as_decimal(entry_array)
      assert result == Decimal.new(-6)
    end

    test "one positive decimal for yardi charges", ~M[yardi_charge] do
      entry_array = [yardi_charge]
      result = ExternalLedgerBoundary.balance_as_decimal(entry_array)
      assert result == Decimal.new(5)
    end

    test "two charges", ~M[yardi_charge] do
      entry_array = [yardi_charge, yardi_charge]
      result = ExternalLedgerBoundary.balance_as_decimal(entry_array)
      assert result == Decimal.new(10)
    end

    test "one charge, one payment", ~M[yardi_charge, yardi_payment] do
      entry_array = [yardi_charge, yardi_payment]
      result = ExternalLedgerBoundary.balance_as_decimal(entry_array)
      assert result == Decimal.new(2)
    end
  end

  describe "yardi_to_map" do
    test "on", ~M[yardi_charge, yardi_payment] do
      entry_array = [yardi_charge, yardi_payment]
      result = ExternalLedgerBoundary.yardi_to_map(entry_array)

      assert result == [
               %{
                 amount: 5,
                 code: nil,
                 date: nil,
                 description: nil,
                 notes: nil,
                 transaction_id: nil,
                 type: "charge"
               },
               %{amount: 3, date: nil, notes: nil, transaction_id: nil, type: "payment"}
             ]
    end
  end
end
