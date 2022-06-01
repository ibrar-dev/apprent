defmodule Mix.Tasks.AppCount.Metrics do
  @moduledoc "Test Metrics for: coverage, loops, credo "
  use Mix.Task

  @shortdoc "Test Metrics for: coverage, loops, credo"
  @spec run(any) :: no_return()
  def run(_) do
    sha = load_sha()
    IO.puts("Running Metrics")
    {cov_output, _number} = run_test_cov()

    IO.puts(header())
    IO.write("|[#{sha}](/AppRent1/apprent_accounting/commit/#{sha}) | #{date()} | ")
    IO.write(one_line(cov_output))
    IO.puts(" |")

    IO.puts("Running Cycle Count")
    {cycles_output, _number} = run_cycle_count()
    cycles_output = String.slice(cycles_output, 0..2)
    IO.puts("Running Credo")
    {credo_lines, _num} = run_credo()

    IO.puts("Running Count Repos")
    run_count_repos()
    IO.puts("Credo : #{credo_lines}")
    IO.puts("Cycles: #{cycles_output}")
    IO.puts("DONE")
  end

  def one_line(test_output) do
    test_output
    |> String.split("\n- ", trim: true)
    |> Enum.map(fn part -> String.slice(part, -6, 4) end)
    |> Enum.join(" | ")
  end

  def date do
    System.cmd("date", ["+%y-%b-%d"], env: [{"MIX_ENV", "test"}])
    |> elem(0)
    |> String.slice(0..8)
  end

  def load_sha do
    System.cmd("git", ["log", "-1"], env: [{"MIX_ENV", "test"}])
    |> elem(0)
    |> String.slice(7..12)
  end

  def header do
    "| sha| date | Coverage   |\n" <>
      "| ---| --- |  --- |\n"
  end

  def run_test_cov do
    {:ok, pwd} = File.cwd()
    IO.puts("Current dir: #{pwd}")
    IO.puts("Please wait...")
    IO.puts("")
    System.cmd("#{pwd}/bin/run_coveralls", [], env: [{"MIX_ENV", "test"}])
  end

  def run_cycle_count do
    {:ok, pwd} = File.cwd()
    System.cmd("#{pwd}/bin/gen_cycles_file", [], env: [{"MIX_ENV", "test"}])
    System.cmd("#{pwd}/bin/run_cycle_count", [], env: [{"MIX_ENV", "test"}])
  end

  def run_credo do
    {:ok, pwd} = File.cwd()
    System.cmd("#{pwd}/bin/run_credo", [], env: [{"MIX_ENV", "test"}])
  end

  def run_count_repos do
    {:ok, pwd} = File.cwd()
    {output, _} = System.cmd("#{pwd}/bin/count_prefix_percentage", [], env: [{"MIX_ENV", "test"}])
    IO.puts(output)
  end
end
