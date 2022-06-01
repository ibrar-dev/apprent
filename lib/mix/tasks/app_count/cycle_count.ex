defmodule Mix.Tasks.AppCount.CycleCount do
  @moduledoc "Count lines in Cycle.txt"
  use Mix.Task

  alias AppCount.Core.Bag
  @shortdoc "Count lines in Cycle.txt"
  @spec run(any) :: no_return()
  def run(_) do
    cycle_count()
  end

  def cycle_count do
    max = 10
    System.cmd("bin/gen_cycles_file", [], env: [{"MIX_ENV", "test"}])
    IO.puts("Full output at: docs/cycles.txt")
    IO.puts("These are files found in loops > #{max} times:")

    bag =
      File.read!("docs/cycles.txt")
      |> String.split("\n", trim: true)
      |> Enum.reduce(Bag.new(), fn line, bag -> Bag.add(bag, line) end)

    bag
    |> Enum.reject(fn {line, _count} -> String.starts_with?(line, "Cycle of length") end)
    |> Enum.reject(fn {_line, count} -> count <= max end)
    |> Enum.sort_by(fn {_line, count} -> count end, &>=/2)
    |> Enum.each(fn {line, count} ->
      IO.puts("#{count}: #{line}")
    end)
  end
end
