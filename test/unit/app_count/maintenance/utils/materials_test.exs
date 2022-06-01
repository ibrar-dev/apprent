defmodule AppCount.Maintenance.Utils.MaterialsTest do
  use AppCount.DataCase
  alias AppCount.Materials.Utils.Materials

  setup do
    order =
      insert(:order)
      |> AppCount.Repo.preload(unit: :property)

    assignment = insert(:assignment, order: order)
    inventory = insert(:inventory)

    order.unit.property
    |> AppCount.Properties.Property.changeset(%{stock_id: inventory.stock_id})
    |> AppCount.Repo.update!()

    {:ok, [assignment: assignment, material: inventory.material]}
  end

  test "get_ref", context do
    %{id: id, name: name} =
      %AppCount.Core.ClientSchema{name: "dasmen", attrs: context.assignment.id}
      |> Materials.get_ref(context.material.ref_number)

    assert id == context.material.id && name == context.material.name
  end
end
