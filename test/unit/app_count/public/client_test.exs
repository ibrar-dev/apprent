defmodule AppCount.Public.ClientTest do
  use AppCount.DataCase
  alias AppCount.Public.Client
  import Ecto.Changeset, only: [get_field: 2]

  setup do
    modules = [
      insert(:module, [name: "Core"], prefix: "public"),
      insert(:module, [], prefix: "public"),
      insert(:module, [], prefix: "public"),
      insert(:module, [], prefix: "public")
    ]

    {:ok, modules: modules}
  end

  test "changeset with no features adds default features" do
    cs =
      %Client{}
      |> Client.changeset(%{name: "Name", schema: "who_cares"})

    features =
      cs
      |> get_field(:client_modules)

    num_features =
      AppCountAuth.Modules.Resources.resource_tree()
      |> Map.keys()
      |> length

    # Core does not get "enabled" it is always enabled
    assert length(features) == num_features - 1
  end

  test "changeset", %{modules: [module1, module2, module3, module4]} do
    cs =
      %Client{}
      |> Client.changeset(%{
        name: "Name",
        schema: "who_cares",
        client_modules: [
          %{module_id: module1.id, enabled: true},
          %{module_id: module2.id, enabled: true},
          %{module_id: module3.id, enabled: false}
        ]
      })

    assert get_field(cs, :name) == "Name"

    features =
      cs
      |> get_field(:client_modules)
      |> Enum.into(
        %{},
        fn feature ->
          {feature.module_id, feature.enabled}
        end
      )

    assert features[module1.id]
    assert features[module2.id]
    assert features[module3.id] == false
    assert features[module4.id] == false
  end

  test "changeset/2 invalid", %{modules: [module1, module2, _module3, _module4]} do
    cs =
      %Client{}
      |> Client.changeset(%{
        schema: "who_cares",
        client_modules: [
          %{module_id: 0, enabled: true},
          %{module_id: module1.id, enabled: true},
          %{module_id: module2.id, enabled: false}
        ]
      })

    assert cs.valid? == false
  end

  test "update_changeset/2", %{modules: [_module1, module2, module3, module4]} do
    features =
      %Client{
        name: "Name",
        client_schema: "who_cares",
        client_modules: [
          %AppCount.Public.ClientModule{module_id: module2.id, enabled: true},
          %AppCount.Public.ClientModule{module_id: module3.id, enabled: true},
          %AppCount.Public.ClientModule{module_id: module4.id, enabled: true}
        ]
      }
      |> Client.update_changeset(%{
        client_modules: [
          %{module_id: module2.id, enabled: false},
          %{module_id: module3.id, enabled: false},
          %{module_id: module4.id, enabled: false}
        ]
      })
      |> get_field(:client_modules)

    assert length(features) == 3
    Enum.each(features, &assert(&1.enabled == false))
  end
end
