defmodule AppCountAuth.Modules.Packing do
  @moduledoc """
    System for encoding admin permissions in very compact numeric form.
    Used to pack admin permissions into auth tokens so the tokens are as small as possible.
  """

  @spec packing_dict(list) :: map
  def packing_dict(resource_list) do
    num_digits = round(length(resource_list) / 2)
    indexed = Enum.with_index(resource_list)

    Enum.into(
      indexed,
      %{},
      fn {action, index} ->
        data = if index < num_digits, do: {1, index}, else: {3, index - num_digits}
        {action, data}
      end
    )
  end

  @spec packing_data(list) :: map
  def packing_data(resources) do
    %{dict: packing_dict(resources), size: round(length(resources) / 2)}
  end

  @spec pack_permissions(map, Keyword.t()) :: Integer.t()
  def pack_permissions(%{dict: packing_dict, size: num_digits}, permissions) do
    empty = for _i <- 1..num_digits, do: 0

    packing_dict
    |> Enum.reduce(
      empty,
      fn {action, {multiplier, target_index}}, acc ->
        base_value =
          case permissions[action] do
            :read -> multiplier
            :write -> multiplier * 2
            nil -> 0
          end

        new_value = Enum.at(acc, target_index) + base_value
        List.replace_at(acc, target_index, new_value)
      end
    )
    |> List.insert_at(0, 9)
    |> Enum.join()
    |> String.to_integer()
  end

  @spec has_permission?(list, Integer.t(), atom) :: boolean
  def has_permission?(packing_dict, packed, [{resource, action}])
      when action in [:read, :write] do
    case packing_dict[resource] do
      nil ->
        raise "resource #{resource} is not part of this module"

      {multiplier, target_index} ->
        "#{packed}"
        |> String.replace("9", "")
        |> String.graphemes()
        |> Enum.at(target_index)
        |> String.to_integer()
        |> verify_permission(multiplier, action)
    end
  end

  defp verify_permission(value, 3, :read), do: value in [3, 4, 5, 6, 7, 8]
  defp verify_permission(value, 1, :read), do: value in [1, 2, 4, 5, 7, 8]

  defp verify_permission(value, 3, :write), do: value in [6, 7, 8]
  defp verify_permission(value, 1, :write), do: value in [2, 5, 8]
end
