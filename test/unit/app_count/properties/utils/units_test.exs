defmodule AppCount.Properties.Utils.UnitsTest do
  use AppCount.DataCase
  alias AppCount.Properties
  alias AppCount.Properties.Utils.Units
  alias AppCount.Core.ClientSchema

  @moduletag :properties_units

  setup do
    property = insert(:property)
    unit1 = insert(:unit, property: property)
    unit2 = insert(:unit, property: property)
    {:ok, admin: admin_with_access([property.id]), unit1: unit1, unit2: unit2, property: property}
  end

  test "sort_leases, no leases pass thru" do
    arg = %{leases: []}
    result = Units.sort_leases(arg)
    assert result == arg
  end

  test "list_units_min", %{admin: admin} do
    result = Properties.list_units_min(ClientSchema.new("dasmen", admin))
    assert length(result) == 2
  end

  test "search_units", %{admin: admin, unit1: unit1, unit2: unit2, property: property} do
    expected = [
      %{
        id: unit1.id,
        number: unit1.number,
        property: property.name,
        property_id: property.id,
        tenant: nil,
        tenant_id: nil
      },
      %{
        id: unit2.id,
        number: unit2.number,
        property: property.name,
        property_id: property.id,
        tenant: nil,
        tenant_id: nil
      }
    ]

    assert Enum.sort_by(Properties.search_units(admin), & &1.id) == expected

    expected = [
      %{
        id: unit1.id,
        number: unit1.number,
        property: property.name,
        property_id: property.id,
        tenant_id: nil,
        allow_sms: nil,
        email: nil,
        phone: nil
      }
    ]

    assert Properties.search_units(admin, unit1.number) == expected
  end
end
