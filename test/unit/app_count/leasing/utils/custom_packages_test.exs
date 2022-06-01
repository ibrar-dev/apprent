defmodule AppCount.Leasing.CustomPackagesTest do
  use AppCount.DataCase
  alias AppCount.Leasing.Utils.CustomPackages
  alias AppCount.Leasing.CustomPackage
  alias AppCount.Core.ClientSchema

  @moduletag :leases_custom_packages

  setup do
    {:ok, lease: insert(:leasing_lease), package: insert(:renewal_package)}
  end

  test "Custom packages CRUD", %{lease: lease, package: package} do
    client_schema = "dasmen"

    params = %{
      "lease_id" => lease.id,
      "renewal_package_id" => package.id,
      "amount" => 1500
    }

    CustomPackages.create_custom_package(ClientSchema.new(client_schema, params))

    p =
      Repo.get_by(CustomPackage, [lease_id: lease.id, renewal_package_id: package.id],
        prefix: client_schema
      )

    assert p

    CustomPackages.update_custom_package(ClientSchema.new(client_schema, p.id), %{
      "amount" => 2000
    })

    reloaded = Repo.get(CustomPackage, p.id, prefix: client_schema)
    assert Decimal.to_float(reloaded.amount) == 2000

    admin = insert(:admin)

    CustomPackages.add_note(ClientSchema.new(client_schema, p.id), "Really special note", admin)

    reloaded = Repo.get(CustomPackage, p.id)
    [note] = reloaded.notes
    assert note["admin"] == admin.name
    assert note["text"] == "Really special note"

    CustomPackages.delete_custom_package(ClientSchema.new("dasmen", p.id))
    refute Repo.get(CustomPackage, p.id, prefix: "dasmen")
  end
end
