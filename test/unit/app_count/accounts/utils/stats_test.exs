defmodule AppCount.Accounts.Utils.AccountStatsTest do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Accounts
  alias AppCount.Core.ClientSchema

  @moduletag :accounts_stats

  setup do
    %{unit: unit} = insert_lease()
    {:ok, admin: admin_with_access([unit.property_id]), property: unit.property}
  end

  test "account admin stats", %{admin: admin, property: property} do
    stats = Accounts.admin_stats(ClientSchema.new("dasmen", admin))
    assert stats.logins == 0
    assert stats.applications == 0
    insert(:rent_application, property: property)
    stats = Accounts.admin_stats(ClientSchema.new("dasmen", admin))
    assert stats.applications == 1

    # TODO somebody who know what this function is actually supposed to do should fill out this test
  end
end
