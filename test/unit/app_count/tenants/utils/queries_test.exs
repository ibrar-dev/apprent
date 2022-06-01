defmodule AppCount.Tenants.Utils.QueriesTest do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Tenants.Utils.Queries
  @moduletag :tenants_utils_queries

  setup do
    %{tenants: [tenant], unit: unit} = insert_lease()
    admin = %AppCountAuth.Users.Admin{property_ids: [unit.property_id], client_schema: "dasmen"}

    {
      :ok,
      tenant: tenant, unit: unit, property: unit.property, admin: admin
    }
  end

  test "get_residents_by_type", %{tenant: tenant, unit: unit, admin: admin} do
    [result] = Queries.get_residents_by_type(admin, unit.property_id, "current")
    assert result.id == tenant.id
    assert result.unit == unit.number
    assert result.property_id == unit.property_id
    assert result.name == "#{tenant.first_name} #{tenant.last_name}"
  end
end
