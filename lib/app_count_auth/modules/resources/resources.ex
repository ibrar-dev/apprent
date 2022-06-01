defmodule AppCountAuth.Modules.Resources do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo

  def resource_tree(feature_list \\ nil) do
    module_action_tree(feature_list)
    |> Enum.into(%{}, fn {module_name, actions} ->
      {String.to_atom(module_name), Enum.map(actions, &formatted_action/1)}
    end)
  end

  def compact_resource_tree(feature_list \\ nil) do
    module_action_tree(feature_list)
    |> Enum.into(%{}, fn {module_name, actions} ->
      {String.to_atom(module_name), Enum.map(actions, &formatted_action_slug/1)}
    end)
  end

  defp module_action_tree(nil) do
    module_action_tree_query()
    |> Repo.all(prefix: "public")
  end

  defp module_action_tree(feature_list) do
    module_action_tree_query()
    |> where([module], module.name in ^feature_list or module.name == "Core")
    |> Repo.all(prefix: "public")
  end

  defp module_action_tree_query() do
    from(
      module in AppCountAuth.Module,
      left_join: action in assoc(module, :actions),
      select:
        {module.name,
         jsonize(action, [:id, :module_id, :permission_type, :description], action.id, "ASC")},
      group_by: module.id
    )
  end

  defp formatted_action(action) do
    action
    |> Morphix.atomorphiform!()
    |> Map.take([:id, :module_id, :permission_type, :description])
    |> Map.put(:slug, Slug.slugify(action["description"], separator: ?_))
  end

  defp formatted_action_slug(action) do
    action["description"]
    |> Slug.slugify(separator: ?_)
    |> String.to_atom()
  end
end
