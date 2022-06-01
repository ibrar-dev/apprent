defmodule AppCount.Yardi.ImportResidents.ImportResidentIdsCase do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Yardi.ImportResidentIds
  alias AppCount.Tenants.Tenant
  @moduletag :yardi_import_resident_ids
  @t_codes ["t0027163", "t0023580"]

  setup do
    property = insert(:property, external_id: "2010")
    insert(:processor, property: property, type: "management", name: "Yardi")

    tenant1 =
      insert(:tenant, first_name: "Tisen", last_name: "Edwin", email: "tisenedwin@icloud.com")

    tenant2 =
      insert(:tenant,
        first_name: "Lynnzianna",
        last_name: "Frazier",
        email: "ziannafrazier@gmail.com"
      )

    insert_lease(%{tenants: [tenant1], property: property})
    insert_lease(%{tenants: [tenant2], property: property})
    {:ok, property: property, tenants: [tenant1, tenant2]}
  end

  test "import_residents works", %{tenants: [tenant1, tenant2], property: property} do
    ImportResidentIds.perform(property.id, AppCount.Support.Yardi.FakeGateway)

    [tenant1.id, tenant2.id]
    |> Enum.with_index()
    |> Enum.each(fn {tenant_id, index} ->
      assert Repo.get(Tenant, tenant_id).external_id == Enum.at(@t_codes, index)
    end)
  end
end
