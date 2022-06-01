defmodule AppCount.Properties.SettingsTest do
  use AppCount.DataCase
  alias AppCount.Properties.Settings
  alias AppCount.Core.ClientSchema

  setup do
    property = insert(:property)
    {:ok, [property: property]}
  end

  describe "fetch_by_property_id/1" do
    test "it fetches successfully", %{property: property} do
      assert Settings.fetch_by_property_id(ClientSchema.new("dasmen", property.id))
    end

    test "it handles not finding" do
      assert is_nil(Settings.fetch_by_property_id(ClientSchema.new("dasmen", 0)))
    end
  end
end
