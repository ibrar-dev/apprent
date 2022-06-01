defmodule AppCount.Admins.OrgChartsTest do
  use AppCount.DataCase
  alias AppCount.Repo
  alias AppCount.Admins.Utils.OrgCharts
  alias AppCount.Core.ClientSchema
  @moduletag :orgchart

  setup do
    root = insert(:org_chart)

    {:ok, [root: root]}
  end

  test "make child", context do
    child_id = AppCount.UserHelper.new_admin().id

    OrgCharts.make_child(
      ClientSchema.new("dasmen", child_id),
      context.root.admin.id
    )
    |> Repo.insert(prefix: "dasmen")

    assert OrgCharts.get_admin(ClientSchema.new("dasmen", child_id)).path ==
             [context.root.id]
  end

  test "make child root", _context do
    child_id = AppCount.UserHelper.new_admin().id

    OrgCharts.make_child(
      ClientSchema.new("dasmen", child_id),
      nil
    )
    |> Repo.insert(prefix: "dasmen")

    assert OrgCharts.get_admin(ClientSchema.new("dasmen", child_id)).path ==
             []
  end

  test "index", context do
    new_admin = insert(:admin)

    assert Enum.at(
             OrgCharts.index(ClientSchema.new("dasmen", context.root.id)).admin_list,
             0
           ).admin_id ==
             new_admin.id
  end

  test "delete", context do
    #    delete parent and child child should now be root
    admin = AppCount.UserHelper.new_admin()
    child_id = admin.id

    OrgCharts.make_child(
      ClientSchema.new(admin.user.client.client_schema, child_id),
      context.root.admin.id
    )
    |> Repo.insert(prefix: admin.user.client.client_schema)

    OrgCharts.delete(
      ClientSchema.new(admin.user.client.client_schema, Integer.to_string(context.root.id))
    )

    assert OrgCharts.get_admin(ClientSchema.new(admin.user.client.client_schema, child_id)).path ==
             []
  end
end
