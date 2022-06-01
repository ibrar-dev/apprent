defmodule AppCount.Yardi.ImportLedgerCase do
  use AppCount.DataCase
  alias AppCount.Yardi.ImportLedger
  alias AppCount.Tenants.Tenancy
  @moduletag :yardi_leasing_import_ledger

  setup do
    property = insert(:property, external_id: "1234")
    tenancy = insert(:tenancy, external_id: "t4312")
    {:ok, property: property, tenancy: tenancy}
  end

  test "perform", %{property: property, tenancy: tenancy} do
    insert(:processor, property: property, type: "management", name: "Yardi")
    ImportLedger.perform(property.id, tenancy.id, AppCount.Support.Yardi.FakeGateway)
    decimal_balance = Repo.get(Tenancy, tenancy.id).external_balance
    assert Decimal.to_float(decimal_balance) == -110.50
  end

  test "perform without property integration returns error tuple", %{
    property: property,
    tenancy: tenancy
  } do
    result = ImportLedger.perform(property.id, tenancy.id, AppCount.Support.Yardi.FakeGateway)
    assert result == {:error, "Missing property integration"}
  end
end
