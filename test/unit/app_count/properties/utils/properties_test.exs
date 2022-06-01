defmodule AppCount.Properties.Utils.PropertiesTest do
  use AppCount.DataCase
  alias AppCount.Properties
  alias AppCount.Properties.Property
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Properties.Utils.Properties, as: Subject
  alias AppCount.Core.ClientSchema

  @moduletag :properties_properties

  setup do
    active = insert(:property)
    inactive = insert(:property)

    PropertyRepo.update_property_settings(
      inactive,
      ClientSchema.new(
        "dasmen",
        %{active: false}
      )
    )

    admin = %AppCountAuth.Users.Admin{
      client_schema: "dasmen",
      property_ids: [active.id, inactive.id]
    }

    {:ok, active: active, inactive: inactive, admin: admin}
  end

  @tag :slow
  test "list_active_properties", %{active: active, admin: admin} do
    [active_property] = Properties.list_active_properties(ClientSchema.new("dasmen", admin))
    assert active_property.id == active.id
  end

  test "list_public_properties", %{active: active} do
    [active_property] = Properties.list_public_properties(ClientSchema.new("dasmen", nil))
    assert active_property.id == active.id
  end

  test "get_property", %{active: active, admin: admin} do
    assert Properties.get_property(admin, ClientSchema.new(admin.client_schema, active.id)).id ==
             active.id
  end

  @tag :slow
  test "check_property_configuration", %{active: active} do
    {:error, msg} = Properties.check_property_configuration([active.id])

    assert msg == "Accounts not configured for #{active.name}"

    Enum.each(~w[prepaid receivable cash], fn type ->
      insert(:register, property: active, is_default: true, type: type)
    end)

    {:error, msg} = Properties.check_property_configuration([active.id])

    assert msg == "API credentials not properly configured for #{active.name}"

    Enum.each(~w[screening cc ba lease], fn type ->
      insert(:processor, property: active, name: "Generic Name", type: type)
    end)

    assert Properties.check_property_configuration([active.id]) == true

    {:ok, %Property{}} = PropertyRepo.update(active, %{terms: ""})

    {:error, msg} = Properties.check_property_configuration([active.id])

    assert msg == "No terms and conditions set for #{active.name}"

    PropertyRepo.update_property_settings(
      active,
      ClientSchema.new(
        "dasmen",
        %{default_bank_account_id: nil}
      )
    )

    {:error, msg} = Properties.check_property_configuration([active.id])

    assert msg == "No e-payment bank account for #{active.name}"
  end

  describe "create_property/2" do
    defmodule PropertyRepoParrot do
      use TestParrot
      parrot(:prop_repo, :create_property, {:ok, %{id: 777}})
    end

    test "delegates to PropertyRepo" do
      params = ClientSchema.new("dasmen", %{name: "a Property"})

      # When
      Subject.create_property(params, PropertyRepoParrot)
      # Then
      assert_receive {:create_property, ^params}
    end
  end
end
