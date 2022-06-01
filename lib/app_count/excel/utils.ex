defmodule AppCount.Excel.Utils do
  def to_struct(module, data) when is_list(data), do: Enum.map(data, &to_struct(module, &1))

  def to_struct(module, data) do
    c =
      data
      |> Enum.into(
        %{},
        fn
          {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
          {key, value} when is_atom(key) -> {key, value}
        end
      )

    struct(module, c)
  end
end
