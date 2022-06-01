defmodule AppCount.Leasing.BlueMoon.GetLeaseTest do
  use AppCount.DataCase
  alias AppCount.Leasing.BlueMoon.GetLease
  alias AppCount.Support.HTTPClient
  alias AppCount.Core.ClientSchema

  setup do
    property = insert(:property)
    insert(:processor, property: property, type: "lease", name: "BlueMoon")
    {:ok, property: property}
  end

  test "get_lease return BM lease parameters", %{property: property} do
    AppCount.BlueMoonHelper.mock_bluemoon_responses(["GetLeaseXMLData"])

    %BlueMoon.Data.Lease{} =
      result = GetLease.get_lease(ClientSchema.new("dasmen", property.id), "1234567")

    assert result.code_change_fee == false
    assert Decimal.to_integer(result.rent) == 1100
    assert result.residents == ["Joe Tenant"]
    assert result.fitness_card_numbers == ["11111", "22222", "33333", "44444"]
    HTTPClient.stop()
  end
end
