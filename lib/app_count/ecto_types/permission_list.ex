defmodule AppCount.EctoTypes.PermissionList do
  use Ecto.Type

  def type, do: :map

  def cast(permissions), do: {:ok, permissions}

  def load(permissions) do
    formatted =
      Enum.into(permissions, %{}, fn {k, v} ->
        {format_resource(k), format_action(v)}
      end)

    {:ok, formatted}
  end

  def dump(permissions) do
    {:ok, permissions}
  end

  defp format_resource(resource) when is_binary(resource), do: String.to_atom(resource)
  defp format_action(action) when action in ["read", "write"], do: String.to_atom(action)
end
