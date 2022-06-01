defmodule AppCount.Public.Utils.PropertiesTest do
  use AppCount.DataCase
  alias AppCount.Public.Utils.Properties

  setup do
    {:ok, %{property: insert(:property)}}
  end

  setup do
    property = insert(:property)
    {:ok, public, property} = Properties.sync_public(property)
    {:ok, property: property, public_entry: public}
  end

  describe "sync_public/1" do
    test "creates new public record", %{property: property, public_entry: public} do
      assert public
      assert public.code == property.code
      assert public.schema_id == property.id
      assert Repo.get(AppCount.Properties.Property, property.id).public_property_id == public.id
    end

    test "updates property code in public record", %{property: property, public_entry: public} do
      Properties.sync_public(%{property | code: "new_code"})

      public_record = Repo.get(AppCount.Public.Property, public.id)
      assert public_record
      assert public_record.code == "new_code"
      assert public_record.schema_id == property.id
    end

    test "returns error tuple for non-unique code", %{property: property} do
      {:error, changeset} =
        insert(:property, [code: property.code], prefix: "test")
        |> Properties.sync_public()

      [code: {msg, _}] = changeset.errors
      assert msg == "has already been taken"
    end
  end
end
