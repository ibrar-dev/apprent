defmodule AppCount.Tasks.Workers do
  def list() do
    :code.all_loaded()
    |> Enum.reduce([], fn {mod, _}, acc ->
      if function_exported?(mod, :__is_app_count_worker__, 0) do
        acc ++ [mod]
      else
        acc
      end
    end)
  end

  def list_with_descriptions() do
    list()
    |> Enum.into(%{}, fn module -> {List.last(Module.split(module)), module.desc()} end)
  end
end
