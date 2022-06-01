defmodule Mix.Tasks.TestCoverage do
  @moduledoc "run coverage and open the results"
  use Mix.Task

  @shortdoc "run coverage and open the results"
  @spec run(any) :: no_return()
  def run(_) do
    IO.puts("Running Coveralls ...")
    System.cmd("mix", ["coveralls.html"])
    System.cmd("open", ["cover/excoveralls.html"])
  end
end
