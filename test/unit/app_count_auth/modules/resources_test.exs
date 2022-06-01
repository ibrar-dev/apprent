defmodule AppCountAuth.ResourcesTest do
  use AppCount.DataCase

  test "resource_tree" do
    module = insert(:module, [], prefix: "public")
    action = insert(:action, [module: module], prefix: "public")

    tree = AppCountAuth.Modules.Resources.resource_tree()
    assert hd(tree[String.to_atom(module.name)]).id == action.id
  end
end
