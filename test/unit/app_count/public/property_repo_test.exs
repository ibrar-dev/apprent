defmodule AppCount.Public.PropertyRepoTest do
  use AppCount.DataCase
  alias AppCount.Public.PropertyRepo

  setup do
    property = insert(:property)
    {:ok, public, property} = AppCount.Public.Utils.Properties.sync_public(property)
    {:ok, property: property, public_entry: public}
  end

  describe "client_property_from_code/1" do
    test "gets property based on code", %{property: property, public_entry: public} do
      result = PropertyRepo.client_property_from_code(public.code)
      assert result.id == property.id
      assert public.id == property.public_property_id
      assert result.__meta__.prefix == "dasmen"
    end
  end
end
