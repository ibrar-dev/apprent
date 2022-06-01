defmodule AppCountAuth.Modules.PackingTest do
  use AppCount.Case
  alias AppCountAuth.Modules.Packing

  test "packing_dict" do
    dict =
      [:applications, :properties, :tenants]
      |> Packing.packing_dict()

    assert dict == %{applications: {1, 0}, properties: {1, 1}, tenants: {3, 0}}
  end

  test "packer can pack and unpack permissions lists" do
    packing_data =
      [:properties, :units, :property_settings, :evictions, :admin_permissions, :leases]
      |> Packing.packing_data()

    permissions = [
      properties: :write,
      property_settings: :read,
      evictions: :write,
      admin_permissions: :read,
      leases: :write
    ]

    packed = Packing.pack_permissions(packing_data, permissions)

    assert Packing.has_permission?(packing_data.dict, packed, properties: :write)
    assert Packing.has_permission?(packing_data.dict, packed, properties: :read)
    refute Packing.has_permission?(packing_data.dict, packed, property_settings: :write)
    refute Packing.has_permission?(packing_data.dict, packed, units: :read)
    assert Packing.has_permission?(packing_data.dict, packed, evictions: :write)
    assert Packing.has_permission?(packing_data.dict, packed, admin_permissions: :read)
    assert Packing.has_permission?(packing_data.dict, packed, leases: :read)
    assert Packing.has_permission?(packing_data.dict, packed, leases: :write)

    assert_raise(RuntimeError, "resource applications is not part of this module", fn ->
      Packing.has_permission?(packing_data.dict, packed, applications: :read)
    end)
  end
end
